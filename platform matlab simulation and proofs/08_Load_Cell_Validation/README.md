# Experiment 08: Micro Load-Cell Contact Validation & Safety Interlock Logic

## 1. Safety Architecture: Automated Preload Gate
To prevent operator dependency and tissue pre-stress measurement distortion, the THISULINK platform integrates a precision miniature cantilever beam load cell monitored by an HX711 24-bit $\Sigma\Delta$ ADC. 

The firmware implements a strict contact validation state machine:
- **Target Preload**: $1.50\text{ N}$
- **Allowable Tolerance**: $\pm 0.10\text{ N}$ ($1.40\text{ N} - 1.60\text{ N}$)
- **Preload Noise Floor**: $\sigma_F = 0.015\text{ N}$ (HX711 24-bit filtered)

---

## 2. Firmware Interlock State Machine
$$\text{Status} = \begin{cases}
\text{LOCKOUT: INSUFFICIENT PRELOAD}, & F_{\text{meas}} < 1.40\text{ N} \\
\text{INTERLOCK CLEARED: WAVE LAUNCH AUTHORIZED}, & 1.40\text{ N} \le F_{\text{meas}} \le 1.60\text{ N} \\
\text{LOCKOUT: EXCESSIVE TISSUE PRE-COMPRESSION}, & F_{\text{meas}} > 1.60\text{ N}
\end{cases}$$

The Voice Coil Actuator (VCA) cannot physically trigger unless the HX711 registers a steady 300 ms baseline within the green window.

---

## 3. Results (simulation)
Numbers below are the console output of the script (GNU Octave 11.3 run of `master_run_all`). Synthetic noise comes from `common/det_randn.m`, so MATLAB prints the same values; ODE-based values can differ in the last digit between MATLAB and Octave.

| Trial | True preload | Mean measured (100 samples) | Decision |
|---|---|---|---|
| 1 | 0.85 N | 0.850 N | lockout (insufficient) |
| 2 | 1.32 N | 1.321 N | lockout (insufficient) |
| 3 | 1.51 N | 1.511 N | cleared |
| 4 | 1.58 N | 1.581 N | cleared |
| 5 | 1.85 N | 1.851 N | lockout (excessive) |
| 6 | 3.20 N | 3.201 N | lockout (excessive) |

All six decisions are correct. With σ = 0.015 N and 100-sample averaging (σ_mean ≈ 0.0015 N) misclassification is only possible within a few mN of the 1.40 / 1.60 N limits; this edge case is not tested here.

## 4. Limitations
- Gaussian noise on a constant force; no drift, creep, temperature effects, or foot movement during the 300 ms settle window. Described firmware behaviour is a specification, not tested firmware.

## 5. Generated Figures
- `load_cell_true_vs_measured.png`, `load_cell_validation_limits.png`

---

## How to Run
```matlab
cd('08_Load_Cell_Validation')
experiment_load_cell            % or run master_run_all from the suite root
```
Figures are written to `outputs/08_Load_Cell_Validation/` (git-ignored).
