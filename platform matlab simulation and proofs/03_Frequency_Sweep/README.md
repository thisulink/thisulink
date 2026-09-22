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

## 3. Findings & Resonance Migration
As tissue glycation progresses, the peak acceleration resonance shifts systematically upward:
- Healthy: $21.2\text{ Hz}$ (Peak Acc: $2.8\text{ m/s}^2$)
- Early Glycation: $29.1\text{ Hz}$ (Peak Acc: $3.1\text{ m/s}^2$)
- Diabetic Neuropathy: $38.3\text{ Hz}$ (Peak Acc: $3.4\text{ m/s}^2$)

Tracking the resonant peak across the chirp sweep provides an independent secondary mechanical validation alongside dual-pickup shear wave speed time-of-flight estimation.

---

## 4. Generated Artifacts
- `results/acceleration_frequency_response.png`: Acceleration FRF and resonant peaks.
- `results/displacement_frequency_response.png`: Dynamic indentation amplitude vs frequency.
- `results/phase_response.png`: Acceleration vs force phase angle across $10 - 300\text{ Hz}$.
