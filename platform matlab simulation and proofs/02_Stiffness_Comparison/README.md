# Experiment 02: Plantar Tissue Stiffness Comparison

## 1. Clinical Rationale: Diabetic Glycation vs Compliance
Diabetic peripheral neuropathy and microvascular insufficiency induce non-enzymatic glycation of collagen fibers in the plantar fat pad and plantar fascia. Cross-linking of Advanced Glycation End-products (AGEs) leads to progressive tissue stiffening, loss of hydraulic energy dissipation, and marked increases in peak plantar shear stress during ambulation, preceding plantar ulceration.

This simulation models three distinct diagnostic stages:
1. **Class 1: Healthy Control (Compliant)**: Soft, energy-absorbing tissue ($k = 800\text{ N/m}$, $\mu = 14.5\text{ kPa}$, $c_s = 3.72\text{ m/s}$, $E = 43.5\text{ kPa}$).
2. **Class 2: Early Glycation (Moderate Stiffening)**: Subclinical stiffness increase before sensory loss ($k = 1500\text{ N/m}$, $\mu = 32.0\text{ kPa}$, $c_s = 5.52\text{ m/s}$, $E = 96.0\text{ kPa}$).
3. **Class 3: Diabetic Neuropathy (High Ulceration Risk)**: Severe fibrous stiffening with elevated ulcer risk ($k = 2600\text{ N/m}$, $\mu = 68.0\text{ kPa}$, $c_s = 8.05\text{ m/s}$, $E = 204.0\text{ kPa}$).

---

## 2. Mathematical Relationships
Under isotropic linear elasticity:
$$c_s = \sqrt{\frac{\mu}{\rho}}, \quad E \approx 2\mu(1+\nu) \approx 3\mu \quad (\text{for nearly incompressible soft tissue, } \nu \approx 0.499)$$

The system resonance frequency migrates upward with stiffness:
$$f_n = \frac{1}{2\pi}\sqrt{\frac{k}{m}}$$
- Healthy: $21.22\text{ Hz}$
- Early Glycation: $29.06\text{ Hz}$ ($+37\%$ shift)
- Diabetic Neuropathy: $38.25\text{ Hz}$ ($+80\%$ shift)

---

## 3. Results (simulation)
Numbers below are the console output of the script (GNU Octave 11.3 run of `master_run_all`). Synthetic noise comes from `common/det_randn.m`, so MATLAB prints the same values; ODE-based values can differ in the last digit between MATLAB and Octave.

| Class | $k$ (N/m) | $f_n$ (Hz) | $c_s$ elastic (m/s) | $E$ (kPa) | Steady-state displacement @ 50 Hz | Peak accel. incl. transient |
|---|---|---|---|---|---|---|
| Healthy | 800 | 21.22 | 3.72 | 43.5 | 0.0269 mm | 3.20 m/s² |
| Early glycation | 1500 | 29.06 | 5.52 | 96.0 | 0.0322 mm | 3.97 m/s² |
| Neuropathy | 2600 | 38.26 | 8.05 | 204.0 | 0.0431 mm | 4.72 m/s² |

- The elastic shear speed rises by ~116 % from Class 1 to Class 3 (by construction of the assumed $\mu$ values).
- At 50 Hz all classes are driven **above** resonance (mass-dominated), so the steady-state displacement *increases* with stiffness here (stiffer tissue is closer to resonance). The earlier README statement "0.028 mm → 0.011 mm" was not what the model produces.

## 4. Limitations
- The three classes are assumed parameter sets ("research bands"), not clinically validated stages.

## 5. Generated Figures
- `stiffness_displacement.png`, `stiffness_acceleration.png`, `natural_frequency_comparison.png`, `shear_speed_modulus_comparison.png`

---

## How to Run
```matlab
cd('02_Stiffness_Comparison')
experiment_stiffness            % or run master_run_all from the suite root
```
Figures are written to `outputs/02_Stiffness_Comparison/` (git-ignored).
