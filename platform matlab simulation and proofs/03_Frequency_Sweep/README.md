# Experiment 03: Chirp Frequency Sweep (10 - 300 Hz)

## 1. Excitation Bandwidth & Clinical Optimization
The THISULINK Voice Coil Actuator (VCA) generates a swept sinusoidal chirp covering **$10\text{ Hz}$ to $300\text{ Hz}$**. This frequency spectrum corresponds directly to the optimal shear wave propagation band in plantar soft tissue:
- Below $10\text{ Hz}$: High biological motion noise and bulk foot translation artifacts.
- Above $300\text{ Hz}$: High viscoelastic damping ($\alpha \propto \omega$) causes severe wave attenuation before reaching distal pickups.
- $10 - 300\text{ Hz}$: Provides high spatial phase resolution while maintaining sufficient SNR across both pickup accelerometers.

---

## 2. Dynamic Frequency Response Function (FRF)
The mechanical dynamic compliance transfer function is:
$$H_x(\omega) = \frac{X(\omega)}{F(\omega)} = \frac{1}{(k - m\omega^2) + j(c\omega)}$$

The steady-state acceleration transfer function is:
$$H_a(\omega) = \frac{A(\omega)}{F(\omega)} = -\omega^2 H_x(\omega) = \frac{-\omega^2}{(k - m\omega^2) + j(c\omega)}$$

The mechanical phase angle between acceleration and excitation force is:
$$\phi_a(\omega) = \text{atan2}\left(\text{Im}\{H_a(\omega)\}, \text{Re}\{H_a(\omega)\}\right)$$

---

## 3. Results (simulation)
Numbers below are the console output of the script (GNU Octave 11.3 run of `master_run_all`). Synthetic noise comes from `common/det_randn.m`, so MATLAB prints the same values; ODE-based values can differ in the last digit between MATLAB and Octave.

| Class | Theoretical $f_n$ | Peak of acceleration FRF (1 Hz grid) | Peak acceleration amplitude |
|---|---|---|---|
| Healthy | 21.22 Hz | 22 Hz | 5.45 m/s² |
| Early glycation | 29.06 Hz | 30 Hz | 5.81 m/s² |
| Neuropathy | 38.26 Hz | 40 Hz | 5.46 m/s² |

The acceleration FRF peaks slightly above $f_n$ (by $1/\sqrt{1-2\zeta^2}$ with $\zeta \approx 0.2$), and tends to $F_0/m = 2.22$ m/s² at high frequency.

## 4. Limitations
- Analytical steady-state FRF of the lumped model (no actual chirp time signal is simulated).
- The rationale bullets in Section 1 (below 10 Hz motion noise, above 300 Hz attenuation) are design arguments, not outputs of this script. Experiment 10 shows that attenuation already limits the usable band to 100-200 Hz at the 145 mm pickup.

## 5. Generated Figures
- `acceleration_frequency_response.png`, `displacement_frequency_response.png`, `phase_response.png`

---

## How to Run
```matlab
cd('03_Frequency_Sweep')
experiment_frequency_sweep            % or run master_run_all from the suite root
```
Figures are written to `outputs/03_Frequency_Sweep/` (git-ignored).
