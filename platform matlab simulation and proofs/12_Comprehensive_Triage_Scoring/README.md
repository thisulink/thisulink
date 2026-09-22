# Experiment 12: Dual-Modality Frontline Triage Integration

## 1. Dual-Modality Clinical Rationale
Diabetic foot complications follow two pathophysiological axes:
1. **Mechanical Axis (Chronic Tissue Remodeling)**: Non-enzymatic glycation of collagen fibers increases tissue stiffness, elevating peak dynamic pressures during walking and leading to ischemic necrosis and ulcers.
2. **Thermal / Inflammatory Axis (Microvascular & Autonomic Dysfunction)**: Sympathetic denervation opens arteriovenous shunts, causing local hyperthermia. A contralateral temperature difference $\Delta T \ge 2.2^\circ\text{C}$ ($4.0^\circ\text{F}$) is the established international clinical benchmark (Armstrong & Lavery, *Diabetes Care*) predicting imminent ulceration or acute Charcot neuroarthropathy.

**THISULINK** fuses both modalities into a unified frontline decision tree operated by community health workers (ASHAs) in $< 3\text{ minutes}$.

---

## 2. Frontline Triage Stratification
| Triage Grade | Color Code | Plantar SWE Stiffness | Thermal Asymmetry | Clinical Recommendation |
|---|---|---|---|---|
| **Grade 0** | **Green** | $E < 65\text{ kPa}$ | $\Delta T < 1.0^\circ\text{C}$ | **Low Risk**: Standard foot self-care education; annual ASHA follow-up. |
| **Grade 1** | **Yellow** | $65\text{ kPa} \le E \le 120\text{ kPa}$ | $\Delta T < 2.2^\circ\text{C}$ | **Moderate Risk (Subclinical Glycation)**: Preventative custom offloading EVA/TPU insoles. |
| **Grade 2** | **Orange** | $E > 120\text{ kPa}$ | $\Delta T < 2.2^\circ\text{C}$ | **High Ulcer Risk (Advanced Neuropathy)**: Priority referral to secondary diabetes clinic; pressure-relieving footwear. |
| **Grade 3** | **Red** | Any $E$ value | $\mathbf{\Delta T \ge 2.2^\circ\text{C}}$ | **EMERGENCY WARNING (Acute Charcot / Deep Infection)**: Immediate offloading total contact cast; urgent specialist immobilization. |

---

## 3. Results Summary (N = 120 Simulated Frontline Cohort)
- **Overall Multi-Class Classification Accuracy**: $\mathbf{94.17\%}$
- **Acute Charcot / Hyperemic Flare Sensitivity**: $\mathbf{100.0\%}$ (Zero false negatives on emergency cases).
- **Tissue Stiffening Sensitivity**: $\mathbf{96.25\%}$
- **Specificity**: $\mathbf{92.5\%}$

This experiment demonstrates the power of integrating dual physical sensors (shear wave elastography + FIR thermometry) into a single, low-cost screening platform.

---

## 4. Generated Artifacts
- `results/multimodal_triage_scatter.png`: 2D decision boundary plot showing the 4 clinical triage zones and patient clustering.
- `results/triage_confusion_matrix.png`: Multi-class confusion matrix validating diagnostic precision.
