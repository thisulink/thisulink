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

## 3. Results Summary
- Plantar shear wave velocity increases from $3.72\text{ m/s}$ (healthy) to $8.05\text{ m/s}$ (neuropathic) — a **$> 116\%$ velocity change**, providing a massive diagnostic dynamic range far exceeding standard monofilament sensory thresholds.
- Dynamic compliance displacement decreases from $0.028\text{ mm}$ down to $0.011\text{ mm}$.

---

## 4. Generated Artifacts
- `results/stiffness_displacement.png`: Temporal dynamic displacement waveforms.
- `results/stiffness_acceleration.png`: Temporal surface acceleration comparison.
- `results/natural_frequency_comparison.png`: Fundamental resonance frequency shift across classes.
- `results/shear_speed_modulus_comparison.png`: Shear speed $c_s$ and Young's modulus $E$ across diagnostic classes.
