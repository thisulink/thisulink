# THISULINK Foot Probe — Hardware Design

> **Probe codename**: THISULINK-FP  
> **Purpose**: Plantar shear-wave elastography (SWE) + contact thermometry  
> **MCU**: ESP32-S3-WROOM-1-N16R8  
> **Connectivity**: BLE 5.0 → 73-byte packet → Flutter app

This document covers the bill of materials, wiring, and physical design of the THISULINK foot probe — the custom electromechanical device that drives mechanical shear waves into the plantar surface of the foot and measures the tissue's elastic response with two accelerometers.

> [!NOTE]
> The production probe uses **dual ADXL355** (20-bit industrial-grade accelerometers). The firmware proof-of-concept in [`firmware/`](../firmware/) uses a single ADXL345 (13-bit consumer grade) for pipeline validation. The signal processing pipeline is identical; only the driver and physical constants differ.

---

## 1. How the probe works (physics summary)

```
VCA actuator (electromagnetic, 0.1 N)
        │
        │  Mechanical shear wave injected into plantar tissue
        │  Sweep: 10 Hz → 300 Hz (chirp)
        ▼
   Plantar tissue surface (foot sole)
        │
        ├──► ADXL355 pickup 1 at x₁ = 105 mm from actuator
        │    measures acceleration a₁(t, f)
        │
        └──► ADXL355 pickup 2 at x₂ = 145 mm from actuator
             measures acceleration a₂(t, f)

Phase delay: Δφ(f) = phase(a₂) − phase(a₁)

Shear-wave speed: c_s(f) = 2π·f·Δx / Δφ(f)
  where Δx = x₂ − x₁ = 40 mm

Young's modulus: E ≈ 3ρ·c_s²
  where ρ = 1040 kg/m³ (plantar tissue density)

Tissue classification:
  Class A (Healthy):            c_s = 3.2–4.2 m/s  → E ≤ 50 kPa
  Class B (Early Glycation):    c_s = 4.2–6.5 m/s  → E 51–150 kPa
  Class C (Diabetic Neuropathy):c_s > 6.5 m/s      → E > 150 kPa
```

---

## 2. Bill of materials

### Probe PCB — primary sensing

| # | Component | Part number | Qty | Role |
|---|---|---|---|---|
| U1 | MCU | ESP32-S3-WROOM-1-N16R8 | 1 | Processing, BLE 5.0, SPI master |
| U2 | Accelerometer pickup 1 | ADXL355 (ADXL355BEZ) | 1 | x₁ = 105 mm, 20-bit, ±2.048 g |
| U3 | Accelerometer pickup 2 | ADXL355 (ADXL355BEZ) | 1 | x₂ = 145 mm, Δx = 40 mm |
| U4 | Load cell ADC | HX711 (24-bit) | 1 | Measures contact force from load cell |
| U5 | Load cell | TAL221 5 kg (50 N) strain-gauge | 1 | Contact force 1.40–1.60 N interlock |
| U6 | Thermometer | Melexis MLX90621 16×4 FIR array (I²C) | 1 | 64-pixel plantar thermal map, ΔT ≥ 2.2°C flag |
| U7 | VCA driver IC | DRV8833 or L293D | 1 | H-bridge, drives VCA coil |
| U8 | VCA actuator | LW-65 or equivalent voice-coil actuator | 1 | m = 0.045 kg, F₀ = 0.1 N |
| U9 | Display | SSD1306 OLED 0.96" | 1 | Live c_s / E / tissue class / force |
| U10 | Battery gauge | MAX17048 | 1 | Li-ion SoC over I²C |
| U11 | Charger / PMIC | TP4056 + DW01A protection | 1 | USB-C, 1A charge |
| — | Battery | 3.7 V 2000 mAh Li-ion 18650 | 1 | ~6 h continuous use |
| — | SPI bus capacitors | 100 nF MLCC × 4 | 4 | Decoupling at each sensor |
| — | I²C pull-ups | 4.7 kΩ × 2 | 2 | SDA + SCL |

### Mechanical / physical

| Component | Specification | Purpose |
|---|---|---|
| Velcro strap assembly | k_strap = 12,000 N/m (simulated) | Secures probe to foot, reduces relative motion |
| Lateral flexure mechanism | k_lat = 7,500 N/m (simulated) | Provides lateral compliance, tremor attenuation ≥ 97.5% at 0–5 Hz |
| Probe housing | 3D-printed PETG, 160 × 60 × 30 mm | Holds actuator and two sensor pickups in fixed geometry |
| Sensor spacers | Aluminium 6061, precision-machined | Maintains x₁ = 105 mm, x₂ = 145 mm ± 0.5 mm |
| Coupling pad | Medical-grade silicone gel | Acoustic coupling between probe surface and plantar skin |
| Light shield | Black ABS surround | Prevents photoacoustic interference on IR thermometer |

---

## 3. Pin assignment (ESP32-S3)

### SPI bus — dual ADXL355

| Signal | ESP32-S3 GPIO | Notes |
|---|---|---|
| SCLK | GPIO 12 | Shared clock (3 MHz) |
| MOSI | GPIO 11 | Shared MOSI (ADXL355 is read-only — MOSI used for config only) |
| MISO | GPIO 13 | Shared MISO |
| CS1 (pickup 1) | GPIO 10 | Active LOW — ADXL355 at x₁ = 105 mm |
| CS2 (pickup 2) | GPIO 14 | Active LOW — ADXL355 at x₂ = 145 mm |

### I²C bus

| Signal | ESP32-S3 GPIO | Devices |
|---|---|---|
| SDA | GPIO 8 | HX711, MAX17048, SSD1306, MLX90621 |
| SCL | GPIO 9 | Same |

### VCA driver and load cell

| Signal | ESP32-S3 GPIO | Notes |
|---|---|---|
| VCA_IN1 | GPIO 4 | DRV8833 IN1 — PWM drive (10–300 Hz chirp) |
| VCA_IN2 | GPIO 5 | DRV8833 IN2 — direction control |
| HX711_DATA | GPIO 6 | Load cell 24-bit ADC data |
| HX711_CLK | GPIO 7 | Load cell ADC clock |
| ADXL355_INT1 | GPIO 15 | Data-ready interrupt (both sensors share, CS selects) |

---

## 4. ADXL355 vs ADXL345 — why the upgrade

| Spec | ADXL345 (POC firmware) | ADXL355 (production probe) |
|---|---|---|
| Resolution | 13-bit (12-bit usable at ±16g) | 20-bit |
| Noise floor | ~150 µg/√Hz | **25 µg/√Hz** (6× better) |
| Scale factor | 3.9 mg/LSB | 3.9 **µ**g/LSB (1000× finer) |
| Range | ±2g to ±16g | ±2.048g (optimised for low-vibration measurement) |
| Interface | SPI or I²C | SPI only (up to 10 MHz) |
| Thermal stability | ±0.1% FS/°C | **±0.01% FS/°C** |
| Price | ~\$3 | ~\$12 |

The ADXL345 was used in the firmware POC to validate the entire pipeline (ring buffer, IIR, FFT, feature extraction). The ADXL355 is the production part because its 25 µg/√Hz noise floor is below the shear-wave signal level at the planned 0.1 N drive force.

---

## 5. VCA operating parameters

| Parameter | Value | Source |
|---|---|---|
| Moving mass | m = 0.045 kg | THISULINK probe spec |
| Drive force | F₀ = 0.100 N | THISULINK probe spec |
| Frequency sweep | 10 Hz → 300 Hz, linear chirp | Experiment 03 |
| Drive waveform | Sine, PWM approximated | DRV8833 at 20 kHz carrier |
| Contact preload | 1.50 ± 0.10 N (1.40–1.60 N) | Experiment 08 (HX711 load cell) |
| Bandwidth at F₀ | Determined by Kelvin-Voigt resonance of tissue | Experiments 01–02 |

### Load cell interlock state machine

```
HX711 reads force continuously while probe on foot
        │
        ├─ Force < 1.40 N → "Press harder" LED + no scan
        ├─ Force 1.40–1.60 N → "✅ Contact OK" → scan proceeds
        └─ Force > 1.60 N → "Ease off" LED + no scan
```

---

## 6. Mechanical constants (from MATLAB simulation suite)

All simulation results from `platform matlab simulation and proofs/`:

### Tissue classes

| Class | Young's Modulus E | Shear-wave speed c_s | Spring constant k | Damping µ |
|---|---|---|---|---|
| A — Healthy | 43.5 kPa | 3.72 m/s | 800 N/m | 14.5 kPa |
| B — Early Glycation | 96.0 kPa | 5.52 m/s | 1,500 N/m | 32.0 kPa |
| C — Diabetic Neuropathy | 204 kPa | 8.05 m/s | 2,600 N/m | 68.0 kPa |

### Probe structural constants

| Parameter | Value | Experiment |
|---|---|---|
| Velcro strap stiffness | k_strap = 12,000 N/m | Exp 11 |
| Lateral flexure stiffness | k_lat = 7,500 N/m | Exp 11 |
| Tremor attenuation (0–5 Hz) | ≥ 97.5% | Exp 11 |
| Load cell acceptance rate | > 95% within 1.40–1.60 N | Exp 08 |

---

## 7. BLE output packet (73 bytes)

| Bytes | Field | Type | Units |
|---|---|---|---|
| 0–1 | Header | uint16 | `0x5448` ("TH") |
| 2–3 | Sequence | uint16 | Rolling |
| 4–7 | Timestamp | uint32 | Unix epoch s |
| 8–11 | ADXL355 x1 acceleration | int32 | µg |
| 12–15 | ADXL355 x2 acceleration | int32 | µg |
| 16–19 | Phase delay Δφ | int32 | µrad |
| 20–23 | Shear-wave speed c_s | uint32 | mm/s |
| 24–27 | Young's modulus E | uint32 | Pa |
| 28–31 | Load cell force | uint32 | mN |
| 32–35 | Thermometry ΔT | int32 | m°C |
| 36–39 | VCA drive frequency | uint32 | mHz |
| 40 | Contact status | uint8 | 0=none, 1=OK, 2=out of range |
| 41–71 | Reserved / future use | — | — |
| 72 | CRC8 | uint8 | CRC-8/MAXIM |

**BLE Service UUID**: `0000FFF0-0000-1000-8000-00805F9B34FB`  
**Data Characteristic UUID**: `0000FFF1-0000-1000-8000-00805F9B34FB` (Notify)  
**Command Characteristic UUID**: `0000FFF2-0000-1000-8000-00805F9B34FB` (Write)

---

## 8. Safety and design constraints

> [!CAUTION]
> The VCA actuator applies mechanical vibration to the plantar surface. Drive force must not exceed 0.5 N. The HX711 load cell interlock prevents operation outside the 1.40–1.60 N preload window. Do not use this probe on open wounds, ulcers, or broken skin.

- All exposed surfaces are medical-grade silicone or PETG (skin-contact safe)
- Load cell interlock is a hardware safety gate — cannot be bypassed in software
- VCA PWM frequency limited to 300 Hz maximum in firmware (`config.h`)
- Battery protected by DW01A + FS8205A circuit (overcharge, over-discharge, short-circuit)
- Probe housing is IP42 splash-resistant (not submersible)

---

## 9. Relationship to MATLAB simulation suite

Every hardware parameter in this document traces back to a simulation experiment:

| Hardware parameter | Validated in |
|---|---|
| Tissue class thresholds (E, c_s) | Experiments 01–02, 10 |
| VCA sweep range 10–300 Hz | Experiment 03 |
| Dual-pickup separation Δx = 40 mm | Experiment 10 |
| HX711 interlock window 1.40–1.60 N | Experiment 08 |
| Velcro + flexure tremor suppression | Experiment 11 |
| 120-patient multimodal triage | Experiment 12 |

See [`platform matlab simulation and proofs/README.md`](../platform%20matlab%20simulation%20and%20proofs/README.md) for full simulation details.

---

## 10. Physical Mechanical Calibration

This section documents the calibration procedure for the three primary measurement subsystems of the THISULINK foot probe. All procedures must be executed before clinical use of a new or refurbished unit.

### 10.1 VCA Actuator — Frequency Sweep Verification

The Voice Coil Actuator (VCA) must produce a flat-amplitude chirp from 10 Hz to 300 Hz. Gain roll-off above 200 Hz causes underestimation of tissue stiffness in Class B/C tissue.

**Procedure**

1. Mount the probe on a flat PMMA block (density ≈ 1,190 kg/m³, known shear-wave speed ≈ 1,200 m/s).
2. Apply the standard 1.50 ± 0.10 N preload. Confirm via HX711 serial monitor.
3. Drive the VCA with a 10–300 Hz linear chirp over 200 ms at `F₀ = 0.100 N` (`config.h`: `VCA_FORCE_N 0.1`).
4. Record `a₁(t)` from ADXL355 at x₁ = 105 mm. Apply 256-point FFT.
5. **Pass criterion**: Amplitude variation across 10–300 Hz ≤ ±3 dB. Flag and reject the VCA if any 20-Hz band deviates by > 3 dB.

**Expected chirp parameters (`config.h`)**

| Parameter | Value |
|---|---|
| `VCA_SWEEP_HZ_LOW` | 10 |
| `VCA_SWEEP_HZ_HIGH` | 300 |
| `VCA_CHIRP_DURATION_MS` | 200 |
| `VCA_FORCE_N` | 0.100 |

### 10.2 HX711 + TAL221 Load-Cell — Zero and Span Calibration

The TAL221 5 kg (50 N) strain-gauge load cell paired with the HX711 24-bit ADC provides the contact-force interlock. Incorrect zero introduces a systematic force offset that can violate the 1.40–1.60 N window.

**Procedure**

1. Power the probe with no load applied. Wait 30 seconds for thermal stabilisation.
2. Issue `TARE` command via USB serial. The HX711 registers this zero count internally.
3. Apply a **NIST-traceable calibration mass of 150 g** (1.471 N at g = 9.806 m/s²) to the probe contact surface.
4. Issue `CALIBRATE 1471` (force in millinewtons). Firmware computes the scale factor and writes it to ESP32 NVS flash.
5. Remove and reapply the 150 g mass 5×. Record readback values.
6. **Pass criterion**: Mean readback 1,471 ± 30 mN; standard deviation < 10 mN (CV < 0.7%).
7. Verify the interlock fires: apply a 200 g mass (1.962 N). Firmware must reject the scan and output `ERR_FORCE_HIGH`.

**Interlock window hardcoded in firmware**

```c
#define FORCE_MIN_MN  1400   // 1.40 N
#define FORCE_MAX_MN  1600   // 1.60 N
```

### 10.3 ADXL355 Dual-Accelerometer — Axis Alignment Verification

Both ADXL355 sensors must have their Z-axis orthogonal to the plantar surface (within ±2°). Misalignment couples horizontal motion into the vertical shear-wave measurement, inflating phase-velocity estimates.

**Procedure**

1. Place the assembled probe on a precision granite surface plate (flatness < 5 µm/m).
2. Power on. Read the static DC output of each ADXL355 Z-axis via USB serial.
3. **Pass criterion**: Static Z-axis reading within ±0.035 g of 1.000 g (corresponds to ≤ 2° tilt; ADXL355 resolution 3.9 µg/LSB in ±2.048 g range).
4. If out of tolerance, loosen the sensor PCB retaining screw, re-seat, re-torque to 0.15 N·m, and repeat.

> [!NOTE]
> The ADXL355 has a noise floor of 25 µg/√Hz. At a 4 kHz sampling rate, RMS noise is ≈ 1.77 mg — well below the tissue acceleration signals of 15–80 mg observed in the 10–300 Hz sweep range.

---

## 11. Repeatability Data

> [!IMPORTANT]
> The metrics in this section are **[FUTURE VALIDATION TARGET]** — pre-registered performance targets based on the MATLAB simulation suite (Experiments 01–02, 10–12). Physical repeatability testing on human volunteers has not yet been completed. These targets define the pass/fail criteria for the planned clinical feasibility study.

### 11.1 Shear-Wave Elastography (SWE) — Test-Retest Targets

| Metric | Target | Rationale |
|---|---|---| 
| **Coefficient of Variation (CV%)** | < 5% | Accepted threshold for biomechanical repeatability instruments (Gennisson et al., *Ultrasound Med Biol*, 2013) |
| **Intraclass Correlation Coefficient (ICC, two-way mixed)** | > 0.85 | "Good-to-excellent" reliability per Koo & Mae (*J Chiropr Med*, 2016, PMID 27330520) |
| **Minimum Detectable Change (MDC₉₅)** | < 8 kPa | Must be below the A→B tissue class gap (43.5 kPa → 96 kPa, Δ = 52.5 kPa) |

**Planned protocol**: 15 healthy adult volunteers (age 25–60), 3 repeat measurements per foot per session, 2 sessions separated by 60 minutes (to allow tissue recovery), probe removed and repositioned between each repeat. Primary outcome: ICC for shear-wave speed `c_s`.

### 11.2 Thermometry (MLX90621) — Test-Retest Targets

| Metric | Target |
|---|---|
| Within-session SD of ΔT (left vs. right foot) | < 0.3 °C |
| Between-session ICC of ΔT | > 0.80 |

Threshold for clinical flag: **ΔT ≥ 2.2 °C** (Lavery et al., *Diabetes Care*, 2007, PMID 17192326). The MDC must be < 2.2 °C for the flag to be reliable.

---

## 12. Clinical Reference Comparison

This table compares the THISULINK plantar foot assessment against the closest Indian prior art and standard-of-care devices. The most technically relevant comparison is against **VIBRASENSE** (Ayati Devices / BETiC, IIT Bombay) — the only other CDSCO-approved portable Indian diabetic foot screening device.

| Feature | THISULINK Foot Probe | **VIBRASENSE** (Ayati Devices / BETiC, IIT Bombay) | Biothesiometer (VPT) | 10 g Semmes-Weinstein Monofilament |
|---|---|---|---|---|
| **Core measurement** | Shear-wave elastography (SWE): broadband chirp 10–300 Hz → phase-velocity → Young's modulus E, shear-wave speed c_s | Quantitative Sensory Testing (QST): single-frequency sinusoidal vibration (≤ 6 µm displacement, 12 mm probe tip) → Vibration Perception Threshold (VPT) | VPT at 128 Hz, patient-reported | Pressure threshold at 10 standardised plantar sites, patient-reported |
| **Physical phenomenon** | Propagating travelling shear wave — two-point phase-velocity measurement | Forced standing-wave vibration — single-site perception threshold | Standing-wave vibration — single-site | Static indentation force |
| **What the output represents** | Tissue mechanical stiffness (bulk material property — independent of nerve function) | Sensory nerve conduction function (large-fibre) | Sensory nerve conduction function (large-fibre) | Pressure sensitivity (large-fibre + skin receptor) |
| **Patient cooperation required?** | ❌ No — fully objective; no patient input at any step | ✅ Yes — patient must signal "I feel it now" (subjective endpoint) | ✅ Yes — subjective | ✅ Yes — patient responds |
| **Detects subclinical glycation stiffening?** | ✅ Class B: E rises 43.5 kPa → 96 kPa before nerve-fibre loss (simulation-validated, Experiments 01–02) | ❌ VPT is normal until large-fibre axons are already lost | ❌ Same as VIBRASENSE | ❌ Detects established neuropathy only (sensitivity 66–77%) |
| **Thermal asymmetry channel** | ✅ MLX90621 16×4 FIR array (64 pixels), ΔT ≥ 2.2 °C flag (Lavery et al. 2007, PMID 17192326) | ❌ VIBRASENSE base: none. VIBRASENSE+T: warm/cold perception threshold — patient-reported QST, not objective FIR thermometry | ❌ Not measured | ❌ Not measured |
| **Unit cost (India, 2025)** | ₹12,000–₹18,000 (BOM estimate, field-deployable) | Commercial clinic-pricing (CDSCO-approved, hospital-grade) | ₹10,500–₹40,000 | < ₹500 |
| **Regulatory status** | Prototype — CDSCO submission not yet filed | ✅ CDSCO-approved, Class B medical device | Generally exempt / Class A | Consumable, no registration |
| **Digital output** | ✅ BLE 5.0 → 73-byte packet → Flutter → PocketBase | ✅ Mobile app + digital report | ❌ Manual transcription | ❌ Manual transcription |
| **Evidence base** | MATLAB simulation Experiments 01, 02, 10 (tissue stiffness model) | Clinical studies at MGM Institute of Health Sciences + BETiC | Boulton et al., *Diabetes Care* 2008, PMID 18165342 | Armstrong et al., *Diabetes Care* 1998, PMID 9571335 |

#### Why VPT and SWE detect at different points in the disease

VIBRASENSE and THISULINK are not measuring the same thing. The distinction is mechanistic:

- **VIBRASENSE / biothesiometer** detect at the **nerve-damage stage**: the peripheral nerve axon must already be dysfunctional for VPT to be elevated.
- **THISULINK SWE** targets the **tissue-stiffening stage**: non-enzymatic glycation cross-links collagen fibres in plantar tissue and raises Young's modulus before nerve-fibre loss is clinically detectable.

The disease sequence (per THISULINK's tissue model):

```
Hyperglycaemia
    → non-enzymatic glycation → collagen cross-linking
    → tissue stiffens (E: 43.5 kPa → 96 kPa)          ← THISULINK Class B flag
    → microvascular ischaemia → nerve-fibre axon loss
    → VPT rises                                          ← VIBRASENSE / biothesiometer detects
    → established neuropathy → ulcer risk
```

This means if the mechanistic model is correct, THISULINK would flag patients earlier in the timeline than VIBRASENSE. **This claim is simulation-validated and requires human-subject clinical confirmation against simultaneous VPT measurement — that validation has not been done.**

> [!NOTE]
> "Subclinical detection" claims are based on the tissue stiffness viscoelastic model (MATLAB Experiments 01–02). Physical human-subject validation against simultaneous VIBRASENSE VPT is the highest-priority next step before any clinical deployment claim.

---

## 13. Hardware Consistency Record

This section is a single-source-of-truth for hardware identifiers that must be consistent across firmware, BLE packet specification, and all documentation.

| Item | Value | Source |
|---|---|---|
| **BLE packet header bytes** | `0x54 0x48` (ASCII "TH") | Confirmed in `firmware/src/ble_packet.c`, line 12 |
| **BLE packet total length** | 73 bytes | BLE packet specification v1.2 |
| **BLE CRC algorithm** | CRC-8/MAXIM (poly 0x31, init 0x00) | Confirmed in `firmware/src/crc8.c` |
| **Load cell device** | TAL221 5 kg (50 N) strain-gauge + HX711 24-bit ADC | BOM Rev 3 |
| **Load cell interlock window** | 1.40–1.60 N (1,400–1,600 mN) | `firmware/include/config.h` constants `FORCE_MIN_MN` / `FORCE_MAX_MN` |
| **Accelerometers** | Dual Analog Devices ADXL355 (20-bit, ±2.048 g, 25 µg/√Hz) | BOM Rev 3 |
| **Accelerometer positions** | x₁ = 105 mm, x₂ = 145 mm from VCA contact point; Δx = 40 mm | Experiment 10 (MATLAB simulation) |
| **Thermal sensor** | Melexis MLX90621 — 16×4 FIR thermal array, 64 pixels, I²C | BOM Rev 3; replaces any earlier single-spot MLX90614 references |
| **Thermal flag threshold** | ΔT ≥ 2.2 °C (left vs. right foot asymmetry) | Lavery et al., *Diabetes Care* 2007, PMID 17192326 |
| **VCA actuator parameters** | m = 0.045 kg, F₀ = 0.100 N, sweep 10–300 Hz, chirp 200 ms | Experiment 03 (MATLAB simulation) |
| **MCU** | ESP32-S3-WROOM-1-N16R8 | BOM Rev 3 |
| **Battery** | 3.7 V 2,000 mAh LiPo + DW01A + FS8205A protection circuit | BOM Rev 3 |

> [!CAUTION]
> Any documentation or firmware that references `0xDA 0x7A` as the BLE header, `MLX90614` as the thermal sensor, or a load-cell rating other than TAL221 5 kg (50 N) contains an error introduced by an earlier draft spec (`prompt2.md`). The values in this table are the confirmed correct values.
