# Experiment 12: Dual-Modality Frontline Triage Integration

## 1. Dual-Modality Clinical Rationale
Diabetic foot complications follow two pathophysiological axes:
1. **Mechanical Axis (Chronic Tissue Remodeling)**: Non-enzymatic glycation of collagen fibers increases tissue stiffness, elevating peak dynamic pressures during walking and leading to ischemic necrosis and ulcers.
2. **Thermal / Inflammatory Axis (Microvascular & Autonomic Dysfunction)**: Sympathetic denervation opens arteriovenous shunts, causing local hyperthermia. A contralateral temperature difference $\Delta T \ge 2.2^\circ\text{C}$ ($4.0^\circ\text{F}$) is the established international clinical benchmark (Armstrong & Lavery, *Diabetes Care*) predicting imminent ulceration or acute Charcot neuroarthropathy.

**THISULINK** is designed to fuse both modalities into one frontline decision tree for community health workers. This experiment simulates that decision tree; it is not a clinical evaluation.

---

## 2. Frontline Triage Stratification
| Triage Grade | Color Code | Plantar SWE Stiffness | Thermal Asymmetry | Clinical Recommendation |
|---|---|---|---|---|
| **Grade 0** | **Green** | $E < 65\text{ kPa}$ | $\Delta T < 1.0^\circ\text{C}$ | **Low Risk**: Standard foot self-care education; annual ASHA follow-up. |
| **Grade 1** | **Yellow** | $65\text{ kPa} \le E \le 120\text{ kPa}$ | $\Delta T < 2.2^\circ\text{C}$ | **Moderate Risk (Subclinical Glycation)**: Preventative custom offloading EVA/TPU insoles. |
| **Grade 2** | **Orange** | $E > 120\text{ kPa}$ | $\Delta T < 2.2^\circ\text{C}$ | **High Ulcer Risk (Advanced Neuropathy)**: Priority referral to secondary diabetes clinic; pressure-relieving footwear. |
| **Grade 3** | **Red** | Any $E$ value | $\mathbf{\Delta T \ge 2.2^\circ\text{C}}$ | **EMERGENCY WARNING (Acute Charcot / Deep Infection)**: Immediate offloading total contact cast; urgent specialist immobilization. |

---

Implementation note: a patient with $E < 65$ kPa but $1.0 \le \Delta T < 2.2^\circ$C does not meet the Grade 0 criteria and is assigned Grade 1.

## 3. Simulation Pipeline
1. **Synthetic cohort** (N = 120: 40 healthy, 35 early, 30 neuropathy, 15 Charcot) with assumed group distributions of "true" $E$ and $\Delta T$ (see script header).
2. **Simulated measurement of every patient:** 50 Hz dual-pickup phase difference through `common/shear_wave_propagation_model.m` and the ADXL355 model (`05_Sensor_Simulation/sensor_model.m`), preload randomly inside the 1.40-1.60 N interlock window (Experiment 07 stiffening model), $\Delta T$ noise SD 0.14 °C (NETD 0.1 °C per foot).
3. **Triage rules** from the table above, applied to the *measured* values.

## 4. Results - SIMULATION on synthetic data (not clinical accuracy)
Numbers below are the console output of the script (GNU Octave 11.3 run of `master_run_all`). Synthetic noise comes from `common/det_randn.m`, so MATLAB prints the same values; ODE-based values can differ in the last digit between MATLAB and Octave.

| True group / Predicted | G0 | G1 | G2 | G3 |
|---|---|---|---|---|
| 0 Healthy (40) | 40 | 0 | 0 | 0 |
| 1 Early (35) | 0 | 35 | 0 | 0 |
| 2 Neuropathy (30) | 0 | 1 | 29 | 0 |
| 3 Charcot (15) | 0 | 0 | 0 | 15 |

- 4-class agreement: **99.17 %** (119/120)
- Charcot-flag sensitivity / specificity: 100 % / 100 %
- Any-risk (grade ≥ 1) sensitivity / specificity: 100 % / 100 %
- Simulated $E$ measurement vs true $E$: mean +3.3 % (range -0.5 % to +11.0 %), mainly the viscous bias of the single-frequency estimate (Experiment 10).

**How to read this:** the groups were generated with well-separated means relative to the thresholds, so near-perfect agreement is expected and mostly reflects those assumptions. These numbers are **not** diagnostic accuracy, sensitivity or specificity in patients; that requires a clinical study. The previously quoted 94.17 % came from an older version of the script (different random numbers, no simulated measurement, Grade-0 $\Delta T$ rule not applied).

## 5. Generated Figures
- `multimodal_triage_scatter.png` - measured $E$ vs $\Delta T$ with the triage zones
- `triage_confusion_matrix.png`

---

## How to Run
```matlab
cd('12_Comprehensive_Triage_Scoring')
experiment_multimodal_triage            % or run master_run_all from the suite root
```
Figures are written to `outputs/12_Comprehensive_Triage_Scoring/` (git-ignored).
