# Experiment 01: Baseline Mechanical Response Under Calibrated Preload

## 1. Executive Summary & Clinical Context
The **THISULINK** plantar biomechanical platform launches transient low-frequency shear waves into the plantar heel pad / 1st metatarsal head to evaluate tissue stiffness changes indicative of diabetic neuropathy. 

Before dynamic excitation is triggered, a **$1.50\text{ N}$ static preload** is established by the user resting their foot on the platform (monitored by a high-precision micro load cell). This seats the contactor tip past the non-linear stratum corneum dead layer. Dynamic harmonic excitation ($F_0 = 100\text{ mN}$ at $f_{\text{exc}} = 50\text{ Hz}$) is then applied by the Voice Coil Actuator (VCA).

---

## 2. Governing Equations
The tissue-actuator interface is governed by a 2nd-order Kelvin-Voigt viscoelastic equation of motion:
$$m \ddot{x}(t) + c \dot{x}(t) + k x(t) = F_0 \sin(2\pi f_{\text{exc}} t)$$

Where:
- $m = 0.0450\text{ kg}$ (VCA voice coil + contactor tip moving mass)
- $k = 800.0\text{ N/m}$ (Class 1 Healthy Plantar tissue lumped contact stiffness)
- $c = 2.50\text{ N}\cdot\text{s/m}$ (Viscoelastic damping coefficient)
- $F_0 = 0.100\text{ N}$ ($100\text{ mN}$ harmonic excitation force)
- $f_{\text{exc}} = 50.0\text{ Hz}$ (Nominal diagnostic frequency)

The static tissue indentation under $1.50\text{ N}$ preload is:
$$\delta_{z,\text{static}} = \frac{F_{\text{preload}}}{k} = \frac{1.50\text{ N}}{800.0\text{ N/m}} = 1.875\text{ mm}$$

---

## 3. Results (simulation)
Numbers below are the console output of the script (GNU Octave 11.3 run of `master_run_all`). Synthetic noise comes from `common/det_randn.m`, so MATLAB prints the same values; ODE-based values can differ in the last digit between MATLAB and Octave.

| Quantity | Value |
|---|---|
| Static indentation at 1.50 N | 1.875 mm |
| Natural frequency $f_n$ | 21.22 Hz |
| Steady-state displacement amplitude (50 Hz) | 0.0269 mm (27 µm) |
| Steady-state acceleration amplitude | 2.65 m/s² (0.27 g), within the ADXL355 ±2.048 g range |
| Peak displacement incl. start-up transient | 0.0688 mm |
| Peak acceleration incl. start-up transient | 3.20 m/s² (0.33 g) |

The simulation starts from rest, so the first ~0.3 s contain a transient at $f_n$; the steady-state values are the relevant ones for a continuous 50 Hz drive.

## 4. Limitations
- Lumped 1-DOF mass-spring-damper; $k$, $c$ are assumed values, not measured on tissue.
- "Safe / imperceptible" is not established by this model; it only gives the motion amplitude.

## 5. Generated Figures
- `baseline_force.png`, `baseline_displacement.png`, `baseline_velocity.png`, `baseline_acceleration.png`

---

## How to Run
```matlab
cd('01_Baseline_Mechanical_Response')
experiment_baseline            % or run master_run_all from the suite root
```
Figures are written to `outputs/01_Baseline_Mechanical_Response/` (git-ignored).
