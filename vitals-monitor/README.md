# THISULINK Vitals Monitor — Cuffless BP & Glucose in One Device

> **Device codename**: THISULINK-VM  
> **Form factor**: Handheld, fingertip-contact  
> **MCU**: ESP32-S3-WROOM-1-N16R8  
> **Connectivity**: BLE 5.0 → Flutter App → PocketBase (`thisulink.xyz`)

This document describes how a **single handheld unit** measures both **cuffless blood pressure (BP)** and **blood glucose** — two of the most critical vitals for monitoring diabetic patients in rural India — without requiring a cuff, ECG electrodes, or laboratory equipment.

> [!IMPORTANT]
> BP output from this device is labelled **"PPG-based cuffless blood-pressure estimation"** — a research and screening-assistance measurement, not a clinically validated diagnostic reading. See [Limitations and Safety](#limitations-and-safety). The FDA issued draft guidance in January 2026 specifically addressing clinical performance testing of cuffless BP devices. Individual calibration against a validated cuff monitor is required before use.

---

## Contents

1. [Why one device?](#1-why-one-device)
2. [Hardware bill of materials](#2-hardware-bill-of-materials)
3. [System architecture](#3-system-architecture)
4. [Cuffless BP — how it works](#4-cuffless-bp--how-it-works)
5. [Blood glucose — how it works](#5-blood-glucose--how-it-works)
6. [Signal pipeline (step by step)](#6-signal-pipeline-step-by-step)
7. [ML model for BP estimation](#7-ml-model-for-bp-estimation)
8. [Calibration protocol](#8-calibration-protocol)
9. [BLE output format](#9-ble-output-format)
10. [Firmware overview](#10-firmware-overview)
11. [Integration with THISULINK platform](#11-integration-with-thisulink-platform)
12. [Limitations and safety](#limitations-and-safety)
13. [References](#references)

---

## 1. Why one device?

A diabetic patient in a rural ASHA-worker setting typically needs three vital checks at every visit:

| Vital | Traditional method | THISULINK-VM method |
|---|---|---|
| Blood pressure | Mercury sphygmomanometer or digital cuff (separate device, requires training) | PPG waveform analysis on fingertip — MAX30102 + ML |
| Blood glucose | Glucometer + disposable strip (separate device) | Electrochemical strip + AFE on the same unit |
| Heart rate | Pulse oximeter (separate device) | Derived free from PPG — no extra hardware |

Merging all three into one handheld reduces the ASHA worker's equipment burden from three devices to one, lowers cost, and enables a single BLE stream to the THISULINK Flutter app.

**No ECG is used.** ECG would require additional electrodes, skin-prep, and a separate analog front-end (AD8232), making the device larger and harder to use. Instead, BP is estimated from the **shape** of the PPG pulse wave — an approach supported by a 2024 systematic review of 25 PPG-only BP studies across 21,142 participants (PubMed PMID 40030275).

---

## 2. Hardware bill of materials

### BP + Heart-rate section

| Component | Part | Role |
|---|---|---|
| MCU | ESP32-S3-WROOM-1-N16R8 | Processing, BLE, on-device ML |
| PPG sensor | MAX30102 | Red + IR LEDs, photodetector — fingertip PPG |
| IMU | BMI270 | 6-axis motion — motion-artifact detection |
| Display | SSD1306 OLED 0.96" | Live SBP / DBP / HR / glucose readout |
| Battery gauge | MAX17048 | Li-ion state-of-charge over I²C |
| Battery | 3.7 V 1000 mAh Li-ion | |
| Charger / PMIC | TP4056 + protection circuit | USB-C charging |

### Glucose section (same PCB, separate module)

| Component | Part | Role |
|---|---|---|
| Electrochemical AFE | AFE4490 or LMP91000 | Amperometric strip readout |
| Strip connector | 6-pin ZIF connector | Accepts standard glucometer strip |
| Reference electrode circuit | Op-amp + precision resistor | Stable 3-electrode measurement |

### What was deliberately removed compared to an ECG-based design

| Removed | Why |
|---|---|
| AD8232 ECG AFE | Not needed — PPG-only BP estimation |
| ECG snap electrodes | Not needed |
| ECG lead wires | Not needed |

The result is a **significantly smaller PCB** — fingertip form factor with a single optical window.

---

## 3. System architecture

```
ONE HANDHELD UNIT
│
├─────────────────────────────────────────────────┐
│  CUFFLESS BP + HR                               │
│                                                 │
│   FINGER                                        │
│   ┌──────────────┐                              │
│   │  fingertip   │                              │
│   └──────┬───────┘                              │
│          │                                      │
│   ┌──────▼───────┐   ┌──────────┐              │
│   │   MAX30102   │   │  BMI270  │              │
│   │  RED/IR PPG  │   │  IMU     │              │
│   └──────┬───────┘   └────┬─────┘              │
│          └────────┬────────┘                    │
│                   ▼                             │
│          ┌────────────────┐                     │
│          │   ESP32-S3     │                     │
│          │                │                     │
│          │  Filtering     │                     │
│          │  PWA           │                     │
│          │  ML Model      │                     │
│          └────────┬───────┘                     │
│          SBP  DBP  MAP  HR                      │
│                                                 │
├─────────────────────────────────────────────────┤
│  BLOOD GLUCOSE                                  │
│                                                 │
│   Strip ──► Electrochemical AFE ──► ESP32-S3    │
│                                                 │
├─────────────────────────────────────────────────┤
│  OUTPUT                                         │
│                                                 │
│   SSD1306 OLED (live display)                   │
│   BLE 5.0 → Flutter App → thisulink.xyz         │
└─────────────────────────────────────────────────┘
```

---

## 4. Cuffless BP — how it works

### Why PPG can estimate BP

When the heart contracts, a pressure pulse travels through the arteries. The **MAX30102** shines red (660 nm) and infrared (940 nm) light into the fingertip and measures how much is absorbed. As blood volume changes with each heartbeat, the detector sees a pulsatile waveform — the **photoplethysmogram (PPG)**.

The **shape** of this waveform encodes information about arterial stiffness, pressure, and vascular tone:

```
PPG waveform for one heartbeat

         /\
        /  \
_______/    \__________
↑            ↑
systolic     dicrotic
peak         notch
```

A stiff, high-pressure artery produces a different waveform shape than a compliant, low-pressure one. The ML model learns this relationship from paired PPG + reference cuff measurements.

### Why BMI270 is essential

Motion artifacts corrupt the PPG signal completely. Without motion rejection, the algorithm would output nonsense BP values every time the patient moves.

```
Finger still → Good PPG → BP estimation
Finger moving → Bad PPG → "Please keep finger still" (no output)
```

The BMI270 provides 6-axis (accelerometer + gyroscope) motion data at the same sampling rate as the PPG. A motion-artifact detector runs on the ESP32-S3 and gates the pipeline — only clean segments enter the BP algorithm.

### PPG features used for BP estimation

For each clean pulse wave, the ESP32-S3 extracts:

| Feature category | Features |
|---|---|
| **Amplitude** | Peak amplitude, AC/DC ratio |
| **Timing** | Rise time, fall time, pulse width, systolic time |
| **Morphology** | Dicrotic notch position, notch-to-peak ratio, augmentation index |
| **Area** | Area under systolic peak, total area |
| **Derivatives** | First derivative peak (rate of rise), second derivative features (a, b, c, d, e waves) |
| **Rate** | Heart rate, RR interval, HR variability |

These 18–24 features are the input vector to the on-device ML model.

---

## 5. Blood glucose — how it works

### Electrochemical strip method

The glucose module uses the same **amperometric electrochemical** principle as a standard glucometer:

```
Blood drop on strip
        │
        ▼
Glucose oxidase enzyme
        │  glucose + O₂ → gluconolactone + H₂O₂
        ▼
H₂O₂ + electrode → current proportional to glucose concentration
        │
        ▼
AFE (LMP91000) measures current → ESP32-S3 ADC → mg/dL
```

The AFE applies a precise voltage (typically 0.4 V vs. Ag/AgCl reference) across the working and counter electrodes on the strip. The resulting current follows the **Cottrell equation** — directly proportional to blood glucose concentration. A factory-calibrated lookup table converts raw current (nA) to mg/dL.

### Strip compatibility

The ZIF connector and electrode geometry are designed to accept **standard 3-electrode glucometer strips** (same chemistry as Accu-Chek, OneTouch, etc.). Custom THISULINK-branded strips with optimised enzyme loading are the target for production.

---

## 6. Signal pipeline (step by step)

```
MAX30102 (100–200 Hz)
        │
        ▼ Stage 1 — Acquisition
   Raw PPG (IR channel primary)
   Raw RED channel (SpO₂ secondary)
   BMI270 accelerometer XYZ
        │
        ▼ Stage 2 — Signal conditioning
   DC removal (high-pass filter, fc = 0.5 Hz)
   Band-pass filter (0.5 – 8 Hz, 4th-order Butterworth)
   Motion artifact check (BMI270 RMS vs. threshold)
   ┌── Motion > threshold → discard segment, display "Hold still"
   └── Motion OK → continue
        │
        ▼ Stage 3 — Beat detection
   Adaptive threshold peak detector
   Individual pulse wave segmented (onset → peak → dicrotic notch → next onset)
   Minimum 5 consecutive clean beats required
        │
        ▼ Stage 4 — Feature extraction
   Per-beat: amplitude, rise time, fall time, pulse width,
             area, slopes, 1st derivative, 2nd derivative,
             notch features, AC/DC, HR
   Aggregate: median over 5–10 beats
        │
        ▼ Stage 5 — ML inference (on ESP32-S3)
   Feature vector (18–24 floats)
        │
        ├──► XGBoost / Random Forest (TFLite Micro or ONNX)
        │         ↓
        │    SBP (mmHg)
        │    DBP (mmHg)
        │    MAP (mmHg) = DBP + 1/3 × (SBP − DBP)
        │
        └──► HR (bpm) — directly from peak-to-peak interval
```

---

## 7. ML model for BP estimation

### Model architecture

We evaluate three model families for on-device inference on the ESP32-S3 (240 MHz, 512 KB SRAM):

| Model | Input | Params | Inference time | Notes |
|---|---|---|---|---|
| **XGBoost (primary)** | 18–24 PPG features | ~150 trees | < 5 ms | Easiest to retrain per-patient |
| Random Forest | 18–24 PPG features | ~200 trees | < 8 ms | Good baseline |
| 1D CNN (TFLite Micro) | Raw pulse segment (200 samples) | ~12,000 | ~40 ms | Better generalisation |
| LSTM | Sequence of 5 pulses | ~25,000 | ~80 ms | Best temporal modelling |

**Primary choice**: XGBoost quantised to int8, converted to C array via `m2cgen` for bare-metal ESP32-S3 deployment. No RTOS or Python runtime needed.

### Training data requirements

| Stage | What you need |
|---|---|
| **Personal calibration (minimum)** | 30–50 paired (PPG, cuff BP) measurements from the patient across different BP states (rest, after mild activity) |
| **Population model (for transfer)** | 200+ patients × 30 measurements each |
| **Reference standard** | Validated cuff sphygmomanometer (Omron HEM-7120 or equivalent — AAMI/BHS certified) |

### Loss function

```
L = α × MSE(SBP) + β × MSE(DBP)
    with α = 0.5, β = 0.5
```

Optimise for both systolic and diastolic simultaneously.

### Target accuracy (SIH 2026 prototype goal)

Following AAMI SP10 and BHS protocol (not yet achieved — target):

| Metric | Target |
|---|---|
| Mean error (SBP) | < 5 mmHg |
| Mean error (DBP) | < 5 mmHg |
| Standard deviation | < 8 mmHg |
| BHS grade | Grade B (acceptable for screening) |

> [!NOTE]
> Current PPG-only literature reports mean absolute errors of 6–12 mmHg (SBP) and 4–8 mmHg (DBP) depending on model and calibration strategy (PubMed PMID 40030275). Grade A accuracy (< 5 mmHg mean error, < 8 mmHg SD) is achievable with personalized calibration but not yet reliably demonstrated in subject-independent models.

---

## 8. Calibration protocol

Individual calibration is **required** before the device can produce useful BP estimates. The THISULINK app guides the ASHA worker through a one-time calibration session per patient.

### Steps

```
Step 1 — Reference measurement
  Patient seated, arm at heart level, 5 minutes rest
  ASHA worker takes 3 cuff BP readings (1 min apart)
  Reference = mean of 3 readings
  Enter into Flutter app: SBP / DBP

Step 2 — PPG collection
  Patient places fingertip on MAX30102
  Device collects 60 seconds of PPG
  Minimum 10 clean beats accepted

Step 3 — Pair and store
  (PPG features, reference SBP, reference DBP) → stored in PocketBase
  Repeat on 3 separate visits → 3 paired data points minimum

Step 4 — Model fine-tuning
  Server (PocketBase + Express) fine-tunes the population model
  on the patient's personal paired data
  Updated model weights pushed back to device over BLE

Step 5 — Recalibration
  Repeat every 30 days or after any significant health change
```

---

## 9. BLE output format

The THISULINK-VM streams a single **29-byte BLE notification** every 5 seconds (or on demand):

| Bytes | Field | Type | Units |
|---|---|---|---|
| 0–1 | Header | uint16 | `0x564D` ("VM") |
| 2–3 | Sequence | uint16 | Rolling |
| 4–7 | Timestamp | uint32 | Unix epoch s |
| 8–9 | SBP | uint16 | mmHg × 10 |
| 10–11 | DBP | uint16 | mmHg × 10 |
| 12–13 | MAP | uint16 | mmHg × 10 |
| 14–15 | Heart rate | uint16 | bpm × 10 |
| 16–17 | SpO₂ | uint16 | % × 10 |
| 18–19 | Glucose | uint16 | mg/dL |
| 20 | Signal quality | uint8 | 0–100 % |
| 21 | Motion flag | uint8 | 0=still, 1=motion |
| 22 | Calibration status | uint8 | 0=uncalibrated, 1=calibrated |
| 23 | Strip inserted | uint8 | 0=no, 1=yes |
| 24–27 | Battery % + charge | uint16+uint16 | % and mV |
| 28 | CRC8 | uint8 | CRC-8/MAXIM over 0–27 |

**BLE Service UUID**: `0000AA00-0000-1000-8000-00805F9B34FB`  
**Data Characteristic UUID**: `0000AA01-0000-1000-8000-00805F9B34FB` (Notify)  
**Command Characteristic UUID**: `0000AA02-0000-1000-8000-00805F9B34FB` (Write)

---

## 10. Firmware overview

```
firmware/
├── main/
│   ├── main.c                  App entry, FreeRTOS task spawning
│   ├── ppg_task.c              MAX30102 acquisition (200 Hz)
│   ├── imu_task.c              BMI270 motion monitor (200 Hz)
│   ├── glucose_task.c          AFE strip readout (on demand)
│   ├── signal_processing.c     Filtering, beat detection, feature extraction
│   ├── bp_model.c              XGBoost int8 inference (m2cgen generated)
│   ├── ble_task.c              BLE advertising + GATT server
│   ├── display_task.c          SSD1306 OLED update
│   └── calibration.c           Calibration data store (NVS flash)
├── components/
│   ├── max30102/               Driver for MAX30102
│   ├── bmi270/                 Driver for BMI270
│   ├── lmp91000/               Driver for glucose AFE
│   └── ssd1306/                OLED driver
├── models/
│   └── bp_model_int8.h         Generated C array from trained XGBoost
└── CMakeLists.txt
```

### FreeRTOS tasks and priorities

| Task | Core | Priority | Period |
|---|---|---|---|
| `ppg_task` | Core 1 | High (20) | 5 ms (200 Hz) |
| `imu_task` | Core 1 | High (19) | 5 ms |
| `signal_proc_task` | Core 1 | Medium (15) | 100 ms |
| `bp_inference_task` | Core 0 | Medium (14) | 5 s |
| `glucose_task` | Core 0 | Medium (13) | On demand |
| `ble_task` | Core 0 | High (18) | Event-driven |
| `display_task` | Core 0 | Low (5) | 500 ms |

---

## 11. Integration with THISULINK platform

The THISULINK-VM pairs with the THISULINK Flutter app over BLE. Vitals flow into the same 6-day cycle session as the plantar SWE and retinal readings:

```
THISULINK-VM (BLE)
        │
        ▼
Flutter App (Riverpod state)
        │
        ├── Display: SBP / DBP / HR / Glucose / SpO₂
        ├── Store in local Drift DB
        └── POST to PocketBase cycle_sessions
              │
              ▼
        PocketBase hook (triage.pb.js)
              │
              ▼
        4-tier triage: Green / Yellow / Orange / Red
              │
              ├── SWE modulus E  (from foot probe)
              ├── ΔT thermometry (from foot probe)
              ├── DR grade       (from retinal module)
              ├── SBP / DBP      (from VM device)  ← new inputs
              └── Glucose        (from VM device)
```

### How VM vitals affect triage

| Condition | Triage contribution |
|---|---|
| SBP > 180 mmHg or DBP > 110 mmHg (hypertensive crisis) | → Red |
| SBP 140–179 or DBP 90–109 (Stage 2 hypertension) | → Orange |
| SBP 130–139 or DBP 80–89 (Stage 1 hypertension) | → Yellow |
| Glucose > 400 mg/dL | → Red |
| Glucose 301–400 mg/dL | → Orange |
| Glucose 181–300 mg/dL | → Yellow |

---

## Limitations and Safety

> [!CAUTION]
> This device is a **research and screening-assistance prototype**. It is not a certified medical device. All BP and glucose outputs must be reviewed by a qualified clinician before any treatment decision is made.

### BP estimation

- **Calibration required.** Without a personal calibration session against a validated cuff monitor, the BP output has no clinical meaning.
- **PPG-only accuracy is limited.** Subject-independent (generalised) models currently report mean absolute errors of 6–12 mmHg (SBP) — above the AAMI SP10 Grade A threshold of 5 mmHg.
- **Motion sensitivity.** Even with BMI270 artifact rejection, vigorous hand tremor or shivering can corrupt the PPG signal.
- **Not validated for arrhythmia.** Atrial fibrillation and other rhythm disturbances produce irregular PPG waveforms that break the pulse-wave analysis assumptions.
- **Peripheral vasoconstriction.** Cold hands, low blood volume, or vasopressor medications reduce PPG signal quality and BP estimation accuracy.
- **FDA draft guidance (January 2026)** specifically addresses clinical performance testing requirements for cuffless non-invasive BP devices. This prototype does not yet meet those requirements.
- **Recalibration.** Calibration drifts over time. Recalibrate every 30 days or after any cardiovascular event.

### Glucose

- **Strip-based electrochemical method is validated** — the same principle used in CE- and FDA-cleared glucometers.
- **Hematocrit interference.** Glucose readings can be affected by extreme hematocrit values (< 25% or > 55%).
- **Strip storage.** Strips degrade in heat and humidity. Do not use expired strips.
- **Capillary blood only.** Do not use venous or arterial blood samples without separate validation.

### General

- Not a replacement for a clinical sphygmomanometer or laboratory glucose test.
- All readings are stored with a `research_output` flag in PocketBase. Every output includes a mandatory disclaimer.

---

## References

| Source | Relevance |
|---|---|
| PubMed PMID 40030275 | Systematic review/meta-analysis of 25 PPG-only cuffless BP studies, 21,142 participants |
| PubMed PMID 40231350 | Calibration and recalibration challenges in cuffless BP systems |
| Nature Scientific Reports (2023) | PPG-only deep-learning BP estimation — subject-independent accuracy challenges |
| Armstrong & Lavery, *Diabetes Care* 1997 | ΔT ≥ 2.2°C thermometry threshold for plantar ulceration risk (THISULINK foot probe) |
| FDA Draft Guidance, January 2026 | Cuffless non-invasive BP devices — clinical performance testing requirements |
| Indian consensus on DR screening | Referable DR = ICDR grade ≥ 2 (THISULINK retinal module) |
