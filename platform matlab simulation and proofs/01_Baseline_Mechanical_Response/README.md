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

## 3. Results Summary
- **Dynamic Displacement Amplitude**: $\approx 0.028\text{ mm}$ ($28\ \mu\text{m}$) — ultra-safe, non-invasive, imperceptible to the patient.
- **Dynamic Surface Acceleration**: $\approx 2.76\text{ m/s}^2$ ($0.28\text{ g}$) — comfortably within the ADXL355 full-scale range ($\pm 2.048\text{ g}$).
- **Resonant Frequency**: $f_n = \frac{1}{2\pi}\sqrt{\frac{k}{m}} \approx 21.22\text{ Hz}$.

---

## 4. Generated Artifacts
- `results/baseline_force.png`: Harmonic $100\text{ mN}$ drive profile.
- `results/baseline_displacement.png`: Plantar surface dynamic displacement waveform.
- `results/baseline_velocity.png`: Plantar surface velocity profile.
- `results/baseline_acceleration.png`: Plantar surface acceleration profile.
