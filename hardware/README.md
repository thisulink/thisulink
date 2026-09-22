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
| U5 | Load cell | TAL221 50g or equiv. | 1 | Contact force 1.40–1.60 N interlock |
| U6 | Thermometer | MLX90614ESF (IR) or DS18B20 (contact) | 1 | Contact ΔT measurement |
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
| SDA | GPIO 8 | HX711, MAX17048, SSD1306, MLX90614 |
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
