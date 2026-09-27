# Experiment 07: Contact Preload Force Sensitivity & Interlock Proof

## 1. Biomechanical Rationale: Tissue Hyperelasticity
Human plantar soft tissue exhibits non-linear strain-stiffening behavior (hyperelasticity). When an operator manually presses an ultrasound probe or vibration probe against the foot without mechanical regulation, the applied force varies widely between operators ($0.5\text{ N}$ to $3.5\text{ N}$).

Under excessive preload ($3.0\text{ N}$), the plantar fat pad collagen network is compressed into its stiff locked-up regime, artificially inflating apparent stiffness from $800\text{ N/m}$ up to $1070\text{ N/m}$ ($+33.8\%$ artifactual error!). This false positive can cause a healthy patient to be misdiagnosed with diabetic neuropathy.

Conversely, under-pressure ($< 1.2\text{ N}$) causes acoustic coupling decoupling and slip, creating phase lag jitter and severe under-estimation.

---

## 2. Mathematical Stiffening Model
$$k_{\text{eff}}(F_{\text{preload}}) = k_0 + \alpha \cdot \left(F_{\text{preload}} - F_{\text{target}}\right)$$

Where:
- $k_0 = 800.0\text{ N/m}$ (Unstressed Class 1 baseline)
- $F_{\text{target}} = 1.50\text{ N}$ (THISULINK calibrated static preload)
- $\alpha = 180.0\ (\text{N/m})/\text{N}$ (Empirical plantar contact non-linearity coefficient)

---

## 3. Results (simulation)
Numbers below are the console output of the script (GNU Octave 11.3 run of `master_run_all`). Synthetic noise comes from `common/det_randn.m`, so MATLAB prints the same values; ODE-based values can differ in the last digit between MATLAB and Octave.

| Preload | $k_\text{eff}$ | $f_n$ | $c_s$ @ 50 Hz | Stiffness error | Interlock |
|---|---|---|---|---|---|
| 0.80 N | 674 N/m | 19.48 Hz | 3.53 m/s | -15.8 % | reject (under) |
| 1.40 N | 782 N/m | 20.98 Hz | 3.77 m/s | -2.2 % | accept |
| 1.50 N | 800 N/m | 21.22 Hz | 3.81 m/s | 0.0 % | accept |
| 1.60 N | 818 N/m | 21.46 Hz | 3.85 m/s | +2.2 % | accept |
| 3.00 N | 1070 N/m | 24.54 Hz | 4.36 m/s | +33.8 % | reject (over) |

- Uncontrolled 0.8-3.0 N contact: stiffness error -15.8 % to +33.8 %.
- Inside the 1.40-1.60 N window: |stiffness error| ≤ 2.25 %, |Δf_n| ≤ 0.24 Hz, |Δc_s| ≤ 0.039 m/s.
- $\mu_\text{eff}$ is now scaled from $\mu_A$ with the same factor as $k_\text{eff}$ and $c_s$ comes from the shared viscoelastic model; the old rigid-punch formula ($\mu = k/8r_0$ = 20 kPa) was inconsistent with $\mu_A$ = 14.5 kPa.

## 4. Limitations
- The result follows directly from the **assumed** linear model and $\alpha = 180$ (N/m)/N; it shows why preload should be controlled, it is not a measurement of plantar hyperelasticity.
- Loss of coupling / slip at low preload (Section 1) is not modelled.

## 5. Generated Figures
- `contact_force_vs_stiffness.png`, `preload_error_curve.png`, `contact_force_vs_cs.png`

---

## How to Run
```matlab
cd('07_Contact_Force_Sensitivity')
experiment_contact_force            % or run master_run_all from the suite root
```
Figures are written to `outputs/07_Contact_Force_Sensitivity/` (git-ignored).
