# THISULINK — ESP32-S3 + ADXL345 Firmware
### Mechanical Response Research Proof-of-Concept

> **Hardware**: ESP32-S3 DevKitC-1 + ADXL345 3-axis accelerometer  
> **Interface**: SPI (5 MHz, Mode 3) or I²C (400 kHz) — compile-time switch  
> **Excitation source**: Uncalibrated smartphone vibration (prototype / POC test)  
> **Purpose**: Validate the full data-acquisition and DSP pipeline before integrating the production VCA actuator and dual ADXL355 probes

> [!NOTE]
> This is a **research demonstrator**, not the production THISULINK foot-probe firmware. The sensor here is an **ADXL345** (13-bit, ±16 g, consumer grade). The production probe uses two **ADXL355** sensors (20-bit, ±2 g, industrial grade). The pipeline architecture is identical; only the sensor driver and physical constants differ.

---

## Contents

1. [Firmware architecture](#1-firmware-architecture)
2. [How data flows from silicon to feature vector](#2-how-data-flows-from-silicon-to-feature-vector)
3. [ADXL345 driver — raw acquisition](#3-adxl345-driver--raw-acquisition)
4. [Acquisition engine — ring buffer](#4-acquisition-engine--ring-buffer)
5. [DSP filters — noise and DC removal](#5-dsp-filters--noise-and-dc-removal)
6. [FFT engine — frequency domain analysis](#6-fft-engine--frequency-domain-analysis)
7. [Feature extractor — mechanical feature vector](#7-feature-extractor--mechanical-feature-vector)
8. [Calibration and self-test](#8-calibration-and-self-test)
9. [Operating modes](#9-operating-modes)
10. [File structure](#10-file-structure)
11. [Hardware wiring](#11-hardware-wiring)
12. [How to build and flash](#12-how-to-build-and-flash)

---

## 1. Firmware architecture

Every module is a C++ class. The main sketch (`thisulink_firmware.ino`) constructs one global instance of each and wires them together at `setup()`. The `loop()` is intentionally minimal — it just services the serial console and the acquisition engine, then yields to the FreeRTOS watchdog.

```
thisulink_firmware.ino  (main sketch)
│
├── ADXL345_Driver        Hardware abstraction — SPI/I²C, register R/W,
│                         sample burst, self-test, scale factor
│
├── AcquisitionEngine     Time-based sampling loop — ring buffer (4096 samples),
│                         rate measurement, channel extraction
│
├── DSPFilters            Real-time IIR biquad filter (HPF/LPF/BPF/Notch)
│                         + DC removal + linear detrend
│
├── FFTEngine             Radix-2 Cooley-Tukey FFT with Hann window,
│                         parabolic peak interpolation, harmonic detection
│
├── FeatureExtractor      Time-domain stats + SNR + repeatability across trials
│
├── SensorCalibration     Stationary gravity check (offset bias characterisation)
│
├── PositionManager       Multi-position mechanical response aggregation
│
├── DataLogger            CSV-format serial data dump
│
└── SerialConsole         Interactive command interface (HELP, START, FFT, …)
```

---

## 2. How data flows from silicon to feature vector

```
ADXL345 sensor (MEMS silicon)
        │  SPI 5 MHz or I²C 400 kHz
        │  200 Hz ODR (0x0B in BW_RATE register)
        ▼
┌─────────────────────────────────────────────────────────────────┐
│  ADXL345_Driver::readSample()                                   │
│                                                                 │
│  Raw register bytes [DATAX0..DATAZ1] — little-endian 16-bit    │
│  Two's-complement int16 → multiply by scale factor             │
│                                                                 │
│  FULL_RES mode (bit 3 of DATA_FORMAT = 1):                     │
│    Scale = 0.00390625 g/LSB (constant across all ranges)       │
│    Range ±16g → 13-bit resolution effectively                  │
│                                                                 │
│  sample.x   = raw_x * 0.00390625   [g]                         │
│  sample.y   = raw_y * 0.00390625   [g]                         │
│  sample.z   = raw_z * 0.00390625   [g]                         │
│  sample.mag = √(x² + y² + z²)     [g]                         │
│  sample.timestamp_us = micros()    [µs]                         │
└─────────────────┬───────────────────────────────────────────────┘
                  │  AccelSample struct pushed every 5 ms
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  AcquisitionEngine — ring buffer (4096 samples × 4 channels)   │
│                                                                 │
│  Time-based trigger: (now - lastSampleTime) ≥ 5000 µs          │
│  Overflow handling: oldest sample overwritten, drop counter++   │
│  Real sample rate measured every 400 samples                    │
└─────────────────┬───────────────────────────────────────────────┘
                  │  extractBlock(buffer, channel, N) called by console
                  │  N = sampleRate × acquisitionDuration = 200 × 2 = 400 samples
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  DSPFilters — per-sample real-time IIR biquad                   │
│                                                                 │
│  Stage A: DC offset removal (block mean subtraction)           │
│  Stage B: Linear detrend   (least-squares slope removal)        │
│  Stage C: Active IIR biquad filter (default: HPF at 10 Hz)     │
│           — suppresses gravity DC and postural sway             │
│           — preserves vibration band 10 Hz → 100 Hz            │
└─────────────────┬───────────────────────────────────────────────┘
                  │  rawBuffer[] and filtBuffer[] both kept
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  FFTEngine — Radix-2 Cooley-Tukey FFT                          │
│                                                                 │
│  N = 256 bins, fs = 200 Hz → Δf = 0.78 Hz/bin, window = 2 s   │
│  1. Mean removal                                                │
│  2. Hann window applied (coherent gain = 0.5)                  │
│  3. Bit-reversal permutation                                    │
│  4. Butterfly computation (in-place, float32)                   │
│  5. Single-sided amplitude spectrum with coherent calibration:  │
│       |X[k]| × 2 / (N × coherentGain)                         │
│  6. Peak detection (10 Hz → Nyquist-10 Hz search band)         │
│  7. Parabolic sub-bin interpolation for precision frequency     │
│  8. Spectral centroid + bandwidth                               │
│  9. Noise floor + Peak-to-Noise ratio                          │
│  10. 2nd and 3rd harmonic detection                             │
└─────────────────┬───────────────────────────────────────────────┘
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  FeatureExtractor — MechanicalFeatureVector                     │
│                                                                 │
│  TIME DOMAIN (raw):  mean, RMS, peak, peak-to-peak, σ, energy  │
│  TIME DOMAIN (filt): same metrics on filtered signal            │
│  CREST FACTOR:       peak / RMS (impulsiveness)                 │
│  FREQUENCY DOMAIN:   dominant freq, FFT magnitude, centroid,    │
│                       bandwidth, noise floor, PNR, harmonics    │
│  SNR:                20 × log10(RMS_filt / noise_RMS) [dB]     │
│  REPEATABILITY:      CV% across multiple trials                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. ADXL345 driver — raw acquisition

**File**: [`ADXL345_Driver.cpp`](ADXL345_Driver.cpp)

### Register configuration on `init()`

| Register | Address | Value | Meaning |
|---|---|---|---|
| `POWER_CTL` | 0x2D | `0x00` | Standby (during config) |
| `DATA_FORMAT` | 0x31 | `0x0B` | FULL_RES=1, RANGE=±16g |
| `BW_RATE` | 0x2C | `0x0B` | 200 Hz ODR |
| `FIFO_CTL` | 0x38 | `0x00` | FIFO bypass mode |
| `INT_MAP` | 0x2F | `0x00` | DATA_READY → INT1 |
| `INT_ENABLE` | 0x2E | `0x80` | Enable DATA_READY interrupt |
| `POWER_CTL` | 0x2D | `0x08` | Measurement mode active |

### Scale factor derivation

```
FULL_RES mode: scale = 0.00390625 g/LSB (= 1/256 g/LSB = 3.9 mg/LSB)
This constant holds regardless of the selected range (±2g to ±16g).

At ±16g:
  ADC word: 13 bits effective (signed)
  Max code: ±4096 → ±16.0 g
  Resolution: 32g / 8192 = 3.9 mg/LSB ✓
```

### SPI burst read (6 bytes for X, Y, Z)

```c
// SPI read command: bit7=1 (Read), bit6=1 (Multi-byte), bits[5:0]=start register
transfer(0x80 | 0x40 | 0x32);  // 0xF2 — read from DATAX0, auto-increment
// Receive 6 bytes: DATAX0, DATAX1, DATAY0, DATAY1, DATAZ0, DATAZ1

raw_x = (int16_t)((uint16_t)buf[1] << 8 | buf[0]);  // little-endian
sample.x = (float)raw_x * 0.00390625f;               // convert to g
```

### Self-test routine

1. Collect 50-sample baseline average with self-test off
2. Set `DATA_FORMAT` bit 7 (SELF_TEST) — electrostatic deflection activates
3. Collect 50-sample average with deflection
4. Compute `|delta_x|, |delta_y|, |delta_z|`
5. Compare against ADXL345 datasheet thresholds (X: 0.2g–2.5g, Z: 0.1g–3.0g)
6. Restore normal mode

---

## 4. Acquisition engine — ring buffer

**File**: [`AcquisitionEngine.cpp`](AcquisitionEngine.cpp)

### Why a ring buffer?

The serial console command handler (`SerialConsole`) and the sampling loop run cooperatively in `loop()`. A ring buffer decouples production (sensor polling) from consumption (FFT analysis), so no samples are held up waiting for a console command to finish.

### Buffer specification

| Parameter | Value |
|---|---|
| Size | 4096 samples |
| Element | `AccelSample` {x, y, z, mag, timestamp_us} |
| Overflow policy | Tail advances (oldest sample dropped, `_droppedSamples` counter incremented) |
| Sample trigger | Time-based: `(micros() - lastSampleTime) ≥ 5000 µs` (5 ms = 200 Hz) |

### Why time-based, not interrupt-based?

The ADXL345 `DATA_READY` interrupt works, but over I²C the interrupt can fire before the I²C read completes on the previous sample. Time-based polling at 200 Hz is reliable for this POC across both I²C and SPI without race conditions in Arduino's cooperative loop.

### Measured rate tracking

Every 400 samples, the engine computes:
```
measuredRateHz = 400 × 1,000,000 µs / elapsed_µs
```
This is printed by the console and validates that the hardware is actually sampling at 200 Hz (not drifting).

---

## 5. DSP filters — noise and DC removal

**File**: [`DSPFilters.cpp`](DSPFilters.cpp)

### Why filtering is essential

Raw ADXL345 output in a hand-held / surface-contact experiment contains:
- **DC gravity component** (~1 g on Z-axis, depending on orientation)
- **Postural sway / baseline drift** (0–2 Hz)
- **Mains hum** (50 Hz, especially near switching PSUs)
- **High-frequency quantisation noise** (above the vibration band of interest)

Without filtering, the FFT spectrum is dominated by the DC bin and low-frequency drift. The IIR filter removes this before the FFT window.

### Filter implementation: 2nd-order Biquad IIR

All four filter types (HPF, LPF, BPF, Notch) share the same **Direct Form II Transposed** difference equation:

```
y[n] = b0·x[n] + s1[n-1]
s1[n] = b1·x[n] - a1·y[n] + s2[n-1]
s2[n] = b2·x[n] - a2·y[n]
```

Two state registers (`s1`, `s2`) are sufficient. This form is numerically more stable than Direct Form I at low cut-off frequencies.

### Coefficient derivation (Bilinear transform, Butterworth Q = 1/√2)

All four types computed from the same bilinear transform core:

```
ω₀ = 2π × fc / fs
α  = sin(ω₀) / (2Q)
a0 = 1 + α

HPF:   b0 = (1+cosω₀)/2/a0,  b1 = -(1+cosω₀)/a0,   b2 = b0
LPF:   b0 = (1-cosω₀)/2/a0,  b1 =  (1-cosω₀)/a0,   b2 = b0
BPF:   b0 = sinω₀/2/a0,      b1 = 0,                b2 = -b0
Notch: b0 = 1/a0,             b1 = -2cosω₀/a0,       b2 = b0

a1 = -2cosω₀/a0   (common to all types)
a2 = (1-α)/a0     (common to all types)
```

### Default configuration (startup)

```
HPF at 10 Hz, fs = 200 Hz, Q = 0.7071 (Butterworth)
```

This passes the smartphone vibration band (100–230 Hz fundamental, harmonics above) while rejecting:
- Everything below 10 Hz (gravity DC, postural sway, respiratory artefacts)

### Additional preprocessing (block operations)

These run on the full 2-second buffer *before* the IIR filter is applied:

| Step | Function | What it does |
|---|---|---|
| DC removal | `removeDCOffsetBlock()` | Subtracts block mean. Fast and allocation-free. |
| Linear detrend | `detrendBlock()` | Fits and removes a linear trend (least-squares) — eliminates slow ramp artefacts |

### Nyquist guard

Every `configure*()` call validates that the requested frequency is between 0.1 Hz and 0.98 × Nyquist (98 Hz at 200 Hz). Violations print an error and return `false` without changing the filter state.

> [!NOTE]
> The on-device IIR filter is **causal** (introduces phase delay). For offline analysis in MATLAB, use `filtfilt()` for zero-phase filtering. The firmware deliberately mentions this in its `printFilterSettings()` output.

---

## 6. FFT engine — frequency domain analysis

**File**: [`FFTEngine.cpp`](FFTEngine.cpp)

### Configuration

| Parameter | Value | Effect |
|---|---|---|
| FFT size N | 256 bins | Allocates 256×float for real + imag + window + spectrum |
| Sample rate fs | 200 Hz | Set from `g_sensor.getSampleRate()` |
| Frequency resolution Δf | 200/256 = **0.78 Hz/bin** | Smallest detectable frequency step |
| Time window | 256/200 = **1.28 s** | Samples needed to fill one FFT frame |
| Nyquist limit | 100 Hz | Maximum detectable frequency |

### Processing pipeline inside `compute()`

**Step 1 — Mean removal**
```
mean = Σ x[i] / N
```
Removes DC before windowing (prevents Gibbs phenomenon from DC step).

**Step 2 — Hann window**
```
w[n] = 0.5 × (1 − cos(2πn / (N−1)))
x_windowed[n] = (x[n] − mean) × w[n]
```
Hann window reduces spectral leakage from the sharp edge of the finite data block. Coherent gain = 0.5 (stored as `_coherentGain`).

**Step 3 — Radix-2 Cooley-Tukey FFT**
In-place butterfly computation on the `_real[]` and `_imag[]` arrays after bit-reversal permutation. No external library — runs entirely from heap-allocated float buffers on the ESP32-S3.

**Step 4 — Single-sided amplitude spectrum**
```
|X[k]| = √(real[k]² + imag[k]²) × 2 / (N × coherentGain)
```
The factor of 2 recovers energy from the folded negative-frequency half. Division by coherent gain corrects for Hann window's amplitude reduction.

**Step 5 — Peak detection**
Search band: 10 Hz → 98 Hz (avoids DC artefacts at bin 0).

**Step 6 — Parabolic sub-bin interpolation**
```
δ = 0.5 × (α − γ) / (α − 2β + γ)
f_refined = (peakBin + δ) × Δf
```
Where α = spectrum[peakBin−1], β = spectrum[peakBin], γ = spectrum[peakBin+1]. Achieves frequency resolution better than Δf = 0.78 Hz without increasing N.

**Step 7 — Spectral centroid and bandwidth**
```
centroid = Σ(f[k] × |X[k]|) / Σ|X[k]|
bandwidth = √(Σ((f[k] − centroid)² × |X[k]|) / Σ|X[k]|)
```

**Step 8 — Noise floor and PNR**
Noise floor = mean of all spectrum bins ±3 bins around the peak.
Peak-to-Noise Ratio (PNR) = refined peak magnitude / noise floor.
Also reported in dB: `20 × log10(PNR)`.

**Step 9 — Harmonic detection**
Searches ±2 bins around `2 × f_peak` and `3 × f_peak` for the 2nd and 3rd harmonics.

---

## 7. Feature extractor — mechanical feature vector

**File**: [`FeatureExtractor.cpp`](FeatureExtractor.cpp)

### Output: `MechanicalFeatureVector`

Each analysis run produces one feature vector containing:

**Time domain (raw signal)**

| Feature | Formula | Physical meaning |
|---|---|---|
| Mean | Σx/N | DC offset after pre-processing |
| RMS | √(Σx²/N) | Overall vibration energy level |
| Peak | max|x| | Largest instantaneous acceleration |
| Peak-to-peak | max−min | Total excursion amplitude |
| Variance / σ | sample variance | Signal spread |
| Signal energy | Σx² | Total signal power (unnormalised) |

**Time domain (filtered signal)**
Same metrics computed on the filtered buffer.

**Crest factor**
```
CF = peak_abs / RMS
```
High CF (> 3) indicates impulsive / spiky behaviour. Low CF (≈ 1.4) indicates a sinusoidal signal. This is an indicator of coupling quality.

**Frequency domain (from FFT)**
Dominant frequency, FFT magnitude (Hann-calibrated), spectral centroid, spectral bandwidth, noise floor, PNR, 2nd and 3rd harmonics.

**SNR (dB)**
```
SNR = 20 × log10(RMS_filtered / noise_RMS_baseline)
```
Baseline noise RMS defaults to 1 ADXL345 LSB = 3.9 mg if no calibration has been run.

### Repeatability analysis

`calculateRepeatability()` aggregates up to 32 successive trial `MechanicalFeatureVector` results and computes:
- Mean, standard deviation, and **coefficient of variation (CV%)** for: RMS, peak, dominant frequency, FFT magnitude, and SNR.

**Acceptance criterion**: CV < 10% indicates excellent mechanical coupling repeatability between probe and tissue surface.

---

## 8. Calibration and self-test

**File**: [`SensorCalibration.cpp`](SensorCalibration.cpp)

### Stationary gravity calibration check

On startup, `g_calibration.runCalibration(&g_sensor, 200)` collects 200 stationary samples and computes:

```
|g_vector| = √(mean_x² + mean_y² + mean_z²)
```

Pass condition: `0.85 g ≤ |g_vector| ≤ 1.15 g` (±15% of 1 g nominal).

This confirms:
1. The sensor is mounted and the wiring is correct
2. The scale factor is applied correctly
3. No gross offset bias from assembly

The offset bias on each axis is stored and can be applied as a software calibration offset.

### ADXL345 built-in electrostatic self-test

```
g_sensor.selfTest(stDeltas)
```
This activates the ADXL345's internal electrostatic actuator (SELF_TEST bit in DATA_FORMAT). The expected deflection per the datasheet at 3.3 V:
- X: 0.5g – 2.5g
- Y: 0.5g – 2.5g (opposite sign)
- Z: 0.1g – 3.0g

A `PASS` result confirms that the MEMS element is mechanically functional.

---

## 9. Operating modes

Set by `SystemMode` enum in `config.h`:

| Mode | Command | What happens |
|---|---|---|
| `MODE_IDLE` | — | Console active, no acquisition |
| `MODE_STREAM_RAW` | `STREAM` | Continuous CSV output of raw X,Y,Z,Mag to serial |
| `MODE_CALIBRATE` | `CAL` | 200-sample stationary gravity check |
| `MODE_NOISE_FLOOR` | `NOISE` | Measure baseline noise RMS with no excitation |
| `MODE_PHONE_BASELINE` | `PHONE` | Acquire vibration from smartphone excitation, run full DSP + FFT |
| `MODE_TISSUE_RESPONSE` | `TISSUE` | Same pipeline but with probe on tissue surface |
| `MODE_POSITION_A/B/C` | `POS A/B/C` | Multi-position measurement (3 probe placements, repeatability) |
| `MODE_SELFTEST` | `TEST` | Run ADXL345 built-in electrostatic self-test |

Type `HELP` over serial to see all available commands.

---

## 10. File structure

```
thisulink_firmware/
├── thisulink_firmware.ino   Main sketch — constructs all objects, setup/loop
├── config.h                 All hardware constants, pin assignments, enums
├── ISensor.h                Pure-virtual accelerometer interface
├── ADXL345_Driver.h/.cpp    SPI/I²C driver, register map, scale, self-test
├── SensorCalibration.h/.cpp Stationary gravity check, offset storage
├── AcquisitionEngine.h/.cpp Ring buffer (4096), time-based polling, extraction
├── DSPFilters.h/.cpp        Biquad IIR (HPF/LPF/BPF/Notch), DC removal, detrend
├── FFTEngine.h/.cpp         Radix-2 FFT, Hann window, peak interp, harmonics
├── FeatureExtractor.h/.cpp  Time-domain stats, SNR, repeatability analysis
├── PositionManager.h/.cpp   Multi-position aggregation
├── DataLogger.h/.cpp        CSV serial dump
└── SerialConsole.h/.cpp     Interactive command interface
```

---

## 11. Hardware wiring

### SPI mode (`THISULINK_USE_SPI 1` in `config.h`)

| ADXL345 pin | ESP32-S3 GPIO | Function |
|---|---|---|
| CS | GPIO 10 | Chip Select (active LOW) |
| SDI (MOSI) | GPIO 11 | Data in to ADXL345 |
| SDO (MISO) | GPIO 13 | Data out from ADXL345 |
| SCL (SCLK) | GPIO 12 | Clock (5 MHz, Mode 3: CPOL=1, CPHA=1) |
| VCC | 3.3 V | |
| GND | GND | |
| CS tied HIGH for I²C mode | — | — |

### I²C mode (`THISULINK_USE_SPI 0` in `config.h`)

| ADXL345 pin | ESP32-S3 GPIO | Function |
|---|---|---|
| SDA | GPIO 8 | Data |
| SCL | GPIO 9 | Clock (400 kHz) |
| SDO | GND | I²C address 0x53 |
| CS | 3.3 V | Selects I²C mode |
| VCC | 3.3 V | |
| GND | GND | |

> [!NOTE]
> The `PIN_ADXL_INT1` is defined as GPIO 9 in `config.h` but GPIO 9 is also the I²C SCL pin. In the current POC, the interrupt pin is not used for sampling (time-based polling is used instead). Resolve this conflict before enabling interrupt-driven acquisition on I²C.

---

## 12. How to build and flash

### Arduino IDE settings

| Setting | Value |
|---|---|
| Board | ESP32S3 Dev Module |
| USB CDC On Boot | Enabled |
| Upload Speed | 921600 |
| CPU Frequency | 240 MHz |
| Flash Size | 16 MB (for N16R8 variant) |

### Steps

```bash
# 1. Open thisulink_firmware.ino in Arduino IDE

# 2. Set interface in config.h
#define THISULINK_USE_SPI  1   # for SPI, or
#define THISULINK_USE_SPI  0   # for I²C

# 3. Flash
# Tools → Upload (Ctrl+U)

# 4. Open Serial Monitor at 115200 baud, line ending: Newline

# 5. Type HELP to see all commands
```

### First-run expected output

```
========================================================
  THISULINK - FOOT MECHANICAL RESPONSE RESEARCH POC
  Hardware: ESP32-S3 DevKitC-1 + ADXL345 3-Axis Accel
  Excitation: Uncalibrated Smartphone Vibration Source
========================================================
[INIT] Initializing ADXL345 via Hardware SPI (5 MHz, Mode 3)... SUCCESS (Device ID: 0xE5 verified)

  ADXL345 SENSOR DIAGNOSTICS
  DEVICE ID          : 0xE5 (Expected: 0xE5)
  INTERFACE          : 4-Wire High-Speed SPI (5 MHz, Mode 3)
  RANGE              : +/-16g
  FULL RESOLUTION    : ENABLED (Constant 3.9 mg/LSB)
  OUTPUT DATA RATE   : 200.0 Hz (Analog Bandwidth: 100.0 Hz)

[INIT] Running ADXL345 Electrostatic Self-Test...
[INIT] Self-Test Result: PASSED (dX=0.62g, dY=0.71g, dZ=0.18g)
[INIT] Performing initial stationary gravity calibration check...
[SYSTEM READY] Ready for experimental commands. Type 'HELP' to start.
```

---

## Relationship to production THISULINK probe

| Feature | This POC (ADXL345) | Production probe (ADXL355 × 2) |
|---|---|---|
| Sensor | ADXL345 13-bit, ±16g | ADXL355 20-bit, ±2.048g |
| Resolution | 3.9 mg/LSB | 3.9 µg/LSB (1000× better) |
| Noise floor | ~150 µg/√Hz | 25 µg/√Hz |
| Pickup count | 1 | 2 (at x₁=105 mm, x₂=145 mm) |
| Excitation | Smartphone vibration (uncalibrated) | VCA actuator (0.1 N, 10–300 Hz sweep) |
| Key measurement | Single-point acceleration spectrum | **Phase delay Δφ between x₁ and x₂ → shear-wave speed c_s → Young's modulus E** |
| Software pipeline | This firmware (identical DSP/FFT) | Same modules + dual-channel phase analysis |

The DSP pipeline (acquisition ring buffer → IIR filter → FFT → feature vector) is identical between this POC and production. Only the sensor driver and the phase-delay reconstruction module (`shear_wave_propagation_model.m` in the MATLAB suite) differ.
