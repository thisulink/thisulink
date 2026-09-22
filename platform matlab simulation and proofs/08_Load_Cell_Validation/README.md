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

## 3. Findings & Validation
- **Trial 1 & 2 ($0.85\text{ N}, 1.32\text{ N}$)**: Automatically rejected (`INSUFFICIENT PRELOAD`), preventing wave launch during foot placement transition.
- **Trial 3 & 4 ($1.51\text{ N}, 1.58\text{ N}$)**: Successfully cleared (`WAVE LAUNCH OK`), ensuring calibrated SWE measurements.
- **Trial 5 & 6 ($1.85\text{ N}, 3.20\text{ N}$)**: Instantly interlocked (`EXCESSIVE CONTACT`), protecting patient comfort and preventing hyperelastic non-linear tissue stiffening artifacts.

---

## 4. Generated Artifacts
- `results/load_cell_true_vs_measured.png`: True physical force vs HX711 24-bit digitized force.
- `results/load_cell_validation_limits.png`: Decision boundary plot illustrating interlock clearances and lockouts.
