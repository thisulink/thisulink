# THISULINK: Plantar Biomechanical SWE Platform — MATLAB Simulation Suite & Engineering Proofs

[![SIH 2026 Grand Finale](https://img.shields.io/badge/SIH%202026-Grand%20Finale-green.svg)](https://github.com/thisulink/thisulink)
[![MATLAB Simulation](https://img.shields.io/badge/MATLAB-R2020a--R2024b-blue.svg)](https://github.com/thisulink/thisulink)
[![Modelled Hardware](https://img.shields.io/badge/Modelled%20Hardware-Dual%20ADXL355%20%7C%20VCA%20%7C%20HX711-orange.svg)](https://github.com/thisulink/thisulink)
[![Clinical Focus](https://img.shields.io/badge/Clinical-Diabetic%20Neuropathy%20Triage-red.svg)](https://github.com/thisulink/thisulink)

---

## 1. Executive Summary & Problem Context

**THISULINK** is an integrated dual-modality frontline triage device engineered for **Frontline Health Workers (VHN / ANM / CHO)** to prevent diabetic lower-limb amputations and diabetic retinopathy in under-resourced communities.

This folder contains the **mechanical, biomechanical, electromechanical, and sensor-level simulation suite** (MATLAB / GNU Octave) used to size and sanity-check the **THISULINK Plantar Shear Wave Elastography (SWE) Platform**.

> **Scope:** every result in this folder is a *simulation* with assumed parameters and synthetic data. Nothing here is a bench measurement or clinical evidence. See [Section 8 - Limitations](#8-limitations).

### Why Biomechanical SWE on the Plantar Foot?
Standard clinical triage uses 10-gram monofilaments or tuning forks, which only identify nerve loss after irreversible neuro-ischaemic destruction has occurred. Long before sensory loss, **non-enzymatic glycation** of collagen fibers in the plantar fat pad and fascia causes severe tissue stiffening, loss of energy damping, and elevated shear stresses that cause plantar ulceration.

THISULINK launches non-invasive, low-frequency shear waves ($10 - 300\text{ Hz}$) into the plantar tissue using a precision Voice Coil Actuator (VCA), and tracks wave propagation using dual low-noise digital accelerometers (Analog Devices ADXL355). This allows quantitative extraction of shear wave velocity ($c_s$) and Young's modulus ($E = 3\rho c_s^2$) months before visible lesions or ulceration appear.

```
+---------------------------------------------------------------------------------------+
|                                THISULINK HARDWARE ARCHITECTURE                        |
+---------------------------------------------------------------------------------------+
|                                                                                       |
|   +-------------------+        +--------------------+        +--------------------+   |
|   | Voice Coil (VCA)  |        | Proximal Pickup    |        | Distal Pickup      |   |
|   | 10 - 300 Hz Chirp |=======>| ADXL355 Sensor 1   |=======>| ADXL355 Sensor 2   |   |
|   | F0 = 100 mN       |        | x1 = 105 mm        |        | x2 = 145 mm        |   |
|   +-------------------+        +--------------------+        +--------------------+   |
|            ^                              |                             |             |
|            |                              +--------------+--------------+             |
|            |                                             |                            |
|     +-------------+                        [Phase Difference Delta phi]               |
|     | Load Cell   |                                      |                            |
|     | 1.50 N Gate |                        c_s = (omega * Delta x) / Delta phi        |
|     +-------------+                        E = 3 * rho * c_s^2                        |
|            |                                             |                            |
|    [Preload Interlock]                                   v                            |
|    (1.40 N - 1.60 N)                       +----------------------------+             |
|                                            | THISULINK TRIAGE ENGINE    |             |
|                                            | SWE Modulus + FIR Thermal  |             |
|                                            +----------------------------+             |
+---------------------------------------------------------------------------------------+
```

---

## 2. Platform Mechanical & Hardware Architecture

| Subsystem | Component | Specifications | Clinical / Physical Justification |
|---|---|---|---|
| **Dynamic Actuator** | Linear Voice Coil Actuator (VCA) | $m = 0.045\text{ kg}$, $R = 8.2\ \Omega$, $L = 1.2\text{ mH}$, $K_f = 2.4\text{ N/A}$ | Provides pure decoupled sinusoidal chirp ($10 - 300\text{ Hz}$), eliminating motor harmonic distortion. |
| **Contact Interlock** | Cantilever Micro Load Cell + HX711 | $1.50\text{ N} \pm 0.10\text{ N}$ ($1.40 - 1.60\text{ N}$ allowable gate) | Prevents operator variability and eliminates non-linear hyperelastic tissue pre-compression artifacts. |
| **Pickup Transducers** | Dual ADXL355 Accelerometers | 20-bit ADC, $25\ \mu\text{g}/\sqrt{\text{Hz}}$, $\pm 2.048\text{ g}$, simulated at ODR $4\text{ kHz}$ (LPF $\approx 1\text{ kHz}$) | Simulated 50 Hz phase error $\approx 0.1^\circ$ at the distal pickup (Exp. 06). The current POC firmware uses an ADXL345 at 200 Hz ODR (Nyquist 100 Hz) and cannot cover the full sweep. |
| **Gauge Separation** | Rigid CNC Base Frame | $x_1 = 105\text{ mm}$, $x_2 = 145\text{ mm}$, $\Delta x = 40.0\text{ mm}$ | Inter-sensor phase exceeds $\pi$ above $\approx 46-110\text{ Hz}$ (class dependent), so the sweep must be phase-unwrapped across frequency (Exp. 10). |
| **Tremor Restraint** | Medical Velcro Stabilization Straps | Dual instep & heel belts ($k_{\text{strap}} = 12,000\text{ N/m}$, assumed) | Simulated: an assumed $1.5\text{ mm}$ free-foot tremor ($2 - 5\text{ Hz}$) is reduced to $0.02\text{ mm}$ ($98.7\%$, Exp. 11). |
| **Guide Flexures** | Beryllium Copper Planar Springs | Lateral stiffness $k_{\text{lat}} = 7,500\text{ N/m}$ | Guides normal excitation ($Z$-axis) while clamping rocking and transverse shear motion. |
| **Thermal Sensing** | MLX90621 $16 \times 4$ FIR Array | Differential bilateral sensing, NETD $0.1^\circ\text{C}$ | Detects acute neuropathic inflammation / Charcot warning ($\Delta T_{\text{contra}} \ge 2.2^\circ\text{C}$). |

---

## 3. Plantar Soft-Tissue Biomechanical Classes

The simulation models **three preliminary research mechanical-response bands** of diabetic plantar tissue remodeling ($\rho = 1050\text{ kg/m}^3$). These bands are derived from the Kelvin-Voigt viscoelastic model and literature-sourced tissue parameters — they are not clinically validated stages. Human-subject confirmation against biopsy or established clinical markers has not been performed.

```
+---------------------------------------------------------------------------------------------------------+
|                                    DIAGNOSTIC BIOMECHANICAL CLASSES                                     |
+-------------------+-----------------+-----------------+--------------------+------------------+---------+
| Diagnostic Class  | Contact k (N/m) | Shear Mod. (Pa) | Shear Speed (m/s)  | Young's Modulus  | Damping |
+-------------------+-----------------+-----------------+--------------------+------------------+---------+
| Class 1: Healthy  | 800 N/m         | 14.5 kPa        | 3.72 m/s           | 43.5 kPa         | 2.5 Ns/m|
| Class 2: Early    | 1500 N/m        | 32.0 kPa        | 5.52 m/s           | 96.0 kPa         | 3.2 Ns/m|
| Class 3: Severe   | 2600 N/m        | 68.0 kPa        | 8.05 m/s           | 204.0 kPa        | 4.5 Ns/m|
+-------------------+-----------------+-----------------+--------------------+------------------+---------+
```

---

## 4. Directory Structure & Simulation Modules

```
platform matlab simulation and proofs/
├── master_run_all.m                                  # Runs all 12 experiments, isolated; PASS/FAIL table
├── README.md                                         # This file
├── .gitignore                                        # ignores legacy */results/ folders
├── common/
│   ├── simulation_parameters.m                       # Shared parameters (script; does not clear anything)
│   ├── tissue_model.m                                # 1-DOF Kelvin-Voigt contact ODE
│   ├── shear_wave_propagation_model.m                # 1-D viscoelastic propagation to a pickup (fractional delay)
│   ├── run_experiment_isolated.m                     # Runs one script in its own workspace, restores path/folder
│   ├── det_randn.m                                   # Deterministic normal RNG (same numbers in MATLAB and Octave)
│   ├── fourier_pair.m                                # Coherent single-tone amplitude/phase of two signals
│   ├── results_folder.m                              # outputs/<experiment>/ helper
│   └── bar_colored.m                                 # Per-bar coloured bar chart (MATLAB + Octave)
├── 01_Baseline_Mechanical_Response/                  # 1.5 N preload + 100 mN, 50 Hz response
├── 02_Stiffness_Comparison/                          # Healthy vs early glycation vs neuropathy
├── 03_Frequency_Sweep/                               # 10-300 Hz FRF & resonance shift
├── 04_FFT_Analysis/                                  # Hann-windowed FFT & THD pipeline
├── 05_Sensor_Simulation/                             # Dual ADXL355 digitisation, broadband vs narrow-band SNR
├── 06_Noise_SNR_Analysis/                            # Noise-density sweep, 50 Hz phase error
├── 07_Contact_Force_Sensitivity/                     # Preload stiffening & 1.50 N interlock window
├── 08_Load_Cell_Validation/                          # Load-cell interlock decision logic
├── 09_VCA_Electrical_Test/                           # VCA impedance, current, force, power
├── 10_Shear_Wave_Dispersion_and_Modulus/             # Phase velocity, unwrapping, Kelvin-Voigt modulus fit
├── 11_Velcro_and_Flexure_Tremor_Suppression/         # Tremor suppression by straps + flexures
├── 12_Comprehensive_Triage_Scoring/                  # SWE + thermal triage on a synthetic cohort
└── outputs/                                          # Generated figures + run log - see outputs/README.md
```

---

## 5. Mathematical Formulations & Derivations

### 5.1 Kelvin-Voigt Viscoelastic Wave Propagation
Plantar tissue dynamics under harmonic voice coil excitation:
$$m \ddot{x}(t) + c \dot{x}(t) + k x(t) = F_0 \sin(\omega t)$$

Complex shear modulus:
$$G^*(\omega) = \mu + j \omega \eta$$

Viscoelastic phase velocity $c_s(\omega)$ and spatial attenuation $\alpha(\omega)$:
$$c_s(\omega) = \sqrt{\frac{2(\mu^2 + \omega^2 \eta^2)}{\rho\left(\mu + \sqrt{\mu^2 + \omega^2 \eta^2}\right)}}$$
$$\alpha(\omega) = \sqrt{\frac{\rho \omega^2\left(\sqrt{\mu^2 + \omega^2 \eta^2} - \mu\right)}{2(\mu^2 + \omega^2 \eta^2)}}$$

### 5.2 Dual Pickup Phase Difference Method
Given two ADXL355 pickups at $x_1 = 105\text{ mm}$ and $x_2 = 145\text{ mm}$ ($\Delta x = 40.0\text{ mm}$):
$$\Delta \phi(\omega) = \angle X_1(\omega) - \angle X_2(\omega) \quad (\text{distal lags proximal})$$
$$c_s(\omega) = \frac{\omega \cdot \Delta x}{\Delta \phi(\omega)}$$

**Phase wrapping:** $\Delta\phi$ exceeds $\pi$ above $f = c_s/2\Delta x$ (about 46-110 Hz for $c_s$ = 3.7-8 m/s) and $2\pi$ above $f = c_s/\Delta x$. Experiment 10 measures a stepped sine from 20 Hz and unwraps along frequency; a single-frequency estimate is only safe at low frequency (50 Hz is used for the nominal measurement).

Plantar tissue Young's Modulus $E$ (for nearly incompressible tissue $\nu \approx 0.499$):
$$E \approx 3\mu = 3\rho \cdot c_s^2$$

### 5.3 Tremor Suppression Model (Velcro Straps + Flexures)
$$\left(m_{\text{foot}}\right) \ddot{x} + \left(c_{\text{free}} + c_{\text{strap}}\right) \dot{x} + \left(k_{\text{free}} + k_{\text{strap}} + k_{\text{flex}}\right) x = F_{\text{tremor}}(t)$$

With THISULINK restraints:
$$k_{\text{eff}} = 500 + 12000 + 7500 = \mathbf{20,000\text{ N/m}} \quad (\text{40-fold rigidity increase})$$
With an assumed $1.50\text{ mm}$ free-foot tremor, the simulated clamped amplitude is $0.0195\text{ mm}$ ($98.7\%$ attenuation, Experiment 11).

---

## 6. How to Run the Simulations

### Prerequisites
- MATLAB R2018b or newer (uses `xline`/`yline`), **no toolboxes required**, or
- GNU Octave (tested with **11.3**, no packages required).

### Whole suite
```matlab
% from the folder "platform matlab simulation and proofs"
master_run_all
```
```bash
matlab -batch "master_run_all"
octave --no-gui --eval "master_run_all"   # Windows: use octave-gui.exe --no-gui (qt) so PNG export works
```
- Each experiment runs in its own workspace (`common/run_experiment_isolated.m`); the path and current folder are restored afterwards, a failing experiment is reported and the suite continues.
- Figures go to `outputs/<experiment>/`, the console log to `outputs/master_run_log.txt`. The committed copies
  are indexed with captions in **[outputs/README.md](outputs/README.md)**; re-running the suite overwrites them.
- Runtime ~30 s. On Windows keep the clone path short: Octave cannot write files whose full path exceeds 260 characters.

### Expected output (GNU Octave 11.3, Windows)
```
Exp  Module                                       Result  Time (s)
01   01_Baseline_Mechanical_Response              PASS        2.24
02   02_Stiffness_Comparison                      PASS        3.01
03   03_Frequency_Sweep                           PASS        1.79
04   04_FFT_Analysis                              PASS        1.01
05   05_Sensor_Simulation                         PASS        1.79
06   06_Noise_SNR_Analysis                        PASS        1.68
07   07_Contact_Force_Sensitivity                 PASS        1.99
08   08_Load_Cell_Validation                      PASS        1.53
09   09_VCA_Electrical_Test                       PASS        1.82
10   10_Shear_Wave_Dispersion_and_Modulus         PASS        4.55
11   11_Velcro_and_Flexure_Tremor_Suppression     PASS        2.21
12   12_Comprehensive_Triage_Scoring              PASS        2.31
Passed: 12 / 12
```
"PASS" means the script ran to completion without error; the engineering checks each experiment prints are listed in its README.

### Running individual experiments
```matlab
cd('10_Shear_Wave_Dispersion_and_Modulus')
experiment_shear_wave
```

---

## 7. Simulation Evidence Index

All figures below are outputs of the scripts with the parameters in `common/simulation_parameters.m`.

| Topic | Simulated result | Experiment |
|---|---|---|
| Motion amplitude | 50 Hz steady-state displacement 0.027 mm (healthy) to 0.043 mm (neuropathy) at $F_0$ = 100 mN | 01, 02 |
| Resonance shift | $f_n$ 21.2 → 29.1 → 38.3 Hz; acceleration FRF peaks at 22 / 30 / 40 Hz | 02, 03 |
| Sensor noise | 50 Hz phase error ≈ 0.1° at 25 µg/√Hz; narrow-band SNR ≈ 55 dB at the distal pickup (broadband 18 dB) | 05, 06 |
| Preload control | 0.8-3.0 N gives -15.8 % to +33.8 % stiffness error; inside 1.40-1.60 N ≤ 2.25 % (assumed linear stiffening) | 07, 08 |
| Actuator power | 87.6 mW coil dissipation at 1.20 V; only 0.34 V needed for 100 mN (static-coil model) | 09 |
| Modulus reconstruction | 50 Hz apparent $E$ biased +1 to +5 % by viscosity; Kelvin-Voigt fit over the unwrapped usable band recovers $E$ within 1 % (same model used to generate the data) | 10 |
| Usable band | attenuation limits distal SNR ≥ 20 dB to 20-100 / 140 / 200 Hz (healthy / early / neuropathy) | 10 |
| Tremor suppression | assumed 1.5 mm free tremor → 0.0195 mm clamped (98.7 %, 39 dB in 2-5 Hz) | 11 |
| Triage rules | **SIMULATION on synthetic data:** 99.17 % 4-class agreement (119/120), Charcot flag 100 % sens./spec. on a synthetic N = 120 cohort. Not clinical accuracy. | 12 |

The previously quoted "94.2 % diagnostic accuracy, 100 % sensitivity" is withdrawn: it came from an older script version, was not reproducible, and in any case described synthetic data only.

---

## 8. Limitations
- **Parameters are assumptions.** Tissue classes ($k$, $c$, $\mu$, $\eta$), strap/flexure stiffness, preload stiffening coefficient and cohort distributions are literature-inspired placeholders, not measurements.
- **Simplified physics.** 1-DOF contact model; 1-D narrow-band Kelvin-Voigt propagation with geometric spreading; no tissue layering, boundaries, finite contact size, skin coupling or sensor mounting dynamics.
- **Inverse crime.** Experiments 10 and 12 reconstruct data with the same model that generated it, so their accuracy figures are upper bounds.
- **Hardware.** The simulated sensor is the production dual-ADXL355 probe (ODR 4 kHz). The only existing firmware (ESP32-S3 + ADXL345, 200 Hz ODR, Nyquist 100 Hz) cannot sample the 10-300 Hz sweep. Actuator back-EMF and electronics power are not modelled.
- **No clinical claims.** Triage metrics describe separation of synthetic groups; clinical sensitivity/specificity require a prospective study.

---

## 9. Authors & License
**Project THISULINK**
Integrated Dual-Modality Frontline Diabetic Triage
Smart India Hackathon (SIH) 2026 Grand Finale
Repository: [https://github.com/thisulink/thisulink](https://github.com/thisulink/thisulink)
Licensed under the MIT License.
