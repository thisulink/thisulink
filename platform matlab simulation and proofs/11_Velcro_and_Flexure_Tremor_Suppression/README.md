# Experiment 11: Velcro Stabilization Strap & Planar Flexure Tremor Suppression Proof

## 1. Engineering Motivation & CAD Design Update
During frontline diabetic screening, patients (particularly elderly individuals or those suffering from diabetic autonomic neuropathy or Parkinsonism) frequently exhibit involuntary lower-extremity postural muscle tremors in the **$2 - 5\text{ Hz}$ frequency band**.

In an unconstrained platform:
- Involuntary foot tremors produce large displacement excursions ($\sim 1.50\text{ mm}$), which can misalign the probe and corrupt the phase measurement (quantified with a simple proxy in Section 3).
- To eliminate this critical error source, **THISULINK** integrates:
  1. **Medical-Grade Velcro Stabilization Straps**: Dual hook-and-loop adjustable belts across the instep and heel to clamp the foot firmly against the EVA registration bed.
  2. **Planar Spring Flexures**: Beryllium copper planar flexures that guide the Voice Coil Actuator along the normal $Z$-axis while presenting high lateral stiffness ($k_{\text{lat}} = 7500\text{ N/m}$) against shear rocking.
  3. **Inertial Reaction Base**: $0.58\text{ kg}$ brass ballast mass on elastomer isolation mounts ($f_n < 5\text{ Hz}$).

---

## 2. Dynamic Model
The effective lateral equation of motion is:
$$m_{\text{foot}} \ddot{x} + c_{\text{eff}} \dot{x} + k_{\text{eff}} x = F_{\text{tremor}}(t)$$

Where:
- **Unconstrained Foot**: $k_{\text{eff}} = k_{\text{free}} = 500\text{ N/m}, \quad c_{\text{eff}} = 10\text{ N}\cdot\text{s/m}$
- **THISULINK Constrained Foot**:
  $$k_{\text{eff}} = k_{\text{free}} + k_{\text{strap}} + k_{\text{flex}} = 500 + 12000 + 7500 = \mathbf{20,000\text{ N/m}}$$
  $$c_{\text{eff}} = c_{\text{free}} + c_{\text{strap}} = 10 + 35 = \mathbf{45\text{ N}\cdot\text{s/m}}$$

The system stiffness increases by **40-fold**.

---

## 3. Results (simulation)
Numbers below are the console output of the script (GNU Octave 11.3 run of `master_run_all`). Synthetic noise comes from `common/det_randn.m`, so MATLAB prints the same values; ODE-based values can differ in the last digit between MATLAB and Octave.

The tremor force amplitude is scaled (0.390 N) so that the free foot reaches the **assumed** 1.50 mm peak excursion.

| Condition | Peak displacement | Phase-error proxy |
|---|---|---|
| Unconstrained ($k$ = 500 N/m) | 1.50 mm | ±7.3° |
| Velcro + flexure ($k$ = 20,000 N/m) | 0.0195 mm (19.5 µm) - passes 0.050 mm limit | ±0.09° - passes 1° limit |

- Peak-motion attenuation 98.7 % (37.7 dB); tremor-band (2-5 Hz) PSD rejection 39.0 dB.
- The unconstrained natural frequency (3.25 Hz) lies inside the tremor band, so the free foot is resonance-amplified; that is why the attenuation exceeds the 40x stiffness ratio.

## 4. Limitations
- Lumped 1-DOF foot model; strap and flexure stiffness/damping are design assumptions, not measured.
- The "phase-error proxy" ($k_w \cdot x(t)$) assumes the foot motion changes the propagation path seen by one pickup; in practice both pickups move with the foot and much of it cancels, so it is a pessimistic indicator only. The earlier ±42° / ±0.78° figures were not reproducible.
- The 1.50 mm free-foot tremor amplitude is an assumption.

## 5. Generated Figures
- `tremor_displacement_suppression.png`, `phase_jitter_suppression.png`, `tremor_psd_rejection.png`

---

## How to Run
```matlab
cd('11_Velcro_and_Flexure_Tremor_Suppression')
experiment_stabilization            % or run master_run_all from the suite root
```
Figures are written to `outputs/11_Velcro_and_Flexure_Tremor_Suppression/` (git-ignored).
