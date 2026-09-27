# Experiment 10: Plantar Shear Wave Dispersion & Modulus Reconstruction

## 1. The Core Scientific Innovation of THISULINK
Standard clinical assessment of diabetic peripheral neuropathy relies on the 10-gram Semmes-Weinstein Monofilament (SWM) or tuning forks, which only detect end-stage sensory nerve loss when foot ulceration risk is already imminent.

**THISULINK** pioneers **Plantar Biomechanical Shear Wave Elastography (SWE)** via dual triaxial digital accelerometers without needing expensive, bulky ultrasound systems. By launching low-frequency transient shear waves ($10 - 300\text{ Hz}$) and measuring the phase velocity between two calibrated pickup points, THISULINK quantitatively measures tissue glycation and stiffening months before sensory loss manifests.

---

## 2. Mathematical Reconstruction Pipeline
The dual pickups are spaced at gauge distance $\Delta x = x_2 - x_1 = 40.0\text{ mm}$ ($x_1 = 105\text{ mm}, x_2 = 145\text{ mm}$).

### Phase-Difference Estimation:
$$\Delta \phi(\omega) = \angle X_1(\omega) - \angle X_2(\omega) \quad (\text{distal lags proximal; unwrapped across } \omega)$$

### Phase Velocity:
$$c_s(\omega) = \frac{\omega \cdot \Delta x}{\Delta \phi(\omega)}$$

### Plantar Elastic Modulus:
For nearly incompressible biological soft tissue ($\nu \approx 0.499$):
$$\mu = \rho \cdot c_s^2, \quad E \approx 3\mu = 3\rho \cdot c_s^2$$
where $\rho = 1050\text{ kg/m}^3$ is plantar soft tissue density.

### Viscoelastic Dispersion (Kelvin-Voigt Model):
$$c_s(\omega) = \sqrt{\frac{2(\mu^2 + \omega^2 \eta^2)}{\rho\left(\mu + \sqrt{\mu^2 + \omega^2 \eta^2}\right)}}$$

---

## 3. Phase Wrapping over the 40 mm Baseline
The inter-sensor phase is $\Delta\phi = \omega \Delta x / c_s$. A wrapped estimate (in $(-\pi, \pi]$) becomes ambiguous once $\Delta\phi > \pi$, i.e. above $f = c_s / 2\Delta x$: **~46-50 / 69-80 / 101-110 Hz** for the three classes (elastic vs dispersive $c_s$; the sweep crosses $\pi$ at its 50 / 80 / 110 Hz grid points). Even with the known sign (distal lags proximal) a single frequency is only unambiguous up to $f = c_s/\Delta x$ ≈ 105 / 150 / 220 Hz. The script therefore:
1. measures $\Delta\phi$ with a stepped sine from 20 Hz (where $\Delta\phi < \pi$ for all classes) upwards in 10 Hz steps,
2. **unwraps along frequency** (`unwrap`), and
3. uses only frequencies where the distal Fourier coefficient has SNR ≥ 20 dB.

## 4. Results (simulation)
Numbers below are the console output of the script (GNU Octave 11.3 run of `master_run_all`). Synthetic noise comes from `common/det_randn.m`, so MATLAB prints the same values; ODE-based values can differ in the last digit between MATLAB and Octave.

**Part A - single frequency 50 Hz** ($E_\text{app} = 3\rho c^2$):

| Class | $c_s$ true (viscoelastic) | $c_s$ estimated | Delay | $E = 3\mu$ | $E_\text{app}$ | Bias |
|---|---|---|---|---|---|---|
| Healthy | 3.808 m/s | 3.806 m/s | 10.51 ms | 43.5 kPa | 45.6 kPa | +4.9 % |
| Early glycation | 5.588 m/s | 5.587 m/s | 7.16 ms | 96.0 kPa | 98.3 kPa | +2.4 % |
| Neuropathy | 8.098 m/s | 8.095 m/s | 4.94 ms | 204.0 kPa | 206.4 kPa | +1.2 % |

The phase velocity is recovered almost exactly, but $3\rho c^2$ at a single frequency over-estimates $E$ because viscosity raises the phase velocity.

**Part B - sweep:** usable band (distal SNR ≥ 20 dB) is 20-100 Hz (healthy), 20-140 Hz (early), 20-200 Hz (neuropathy); viscous attenuation, not the sensor bandwidth, limits it. Max phase-velocity error in the usable band: 2.7 % / 1.0 % / 1.0 % with unwrapping, versus > 1000 % for the wrapped estimate.

**Part C - Kelvin-Voigt fit** of $(\mu, \eta)$ to the unwrapped dispersion curve:

| Class | $\mu$ true / fit (kPa) | $\eta$ true / fit (Pa·s) | $E$ true / fit (kPa) | Error |
|---|---|---|---|---|
| Healthy | 14.50 / 14.36 | 12.0 / 13.0 | 43.5 / 43.1 | -0.95 % |
| Early glycation | 32.00 / 31.87 | 18.5 / 19.3 | 96.0 / 95.6 | -0.39 % |
| Neuropathy | 68.00 / 67.99 | 28.0 / 28.3 | 204.0 / 204.0 | -0.01 % |

## 5. Limitations
- **Inverse crime:** the same 1-D Kelvin-Voigt model generates and inverts the data, so these accuracies are an upper bound. Real tissue layering, finite contact size, boundary reflections, coupling and sensor placement errors are not modelled.
- Narrow-band propagation model (one $c_s$, $\alpha$ per excitation frequency, fractional-sample delay by linear interpolation).
- The earlier "0.2 % error" table was not reproducible and ignored the viscous bias.

## 6. Generated Figures
- `shear_wave_dual_pickups.png` - steady-state traces at both pickups (healthy vs neuropathy)
- `modulus_reconstruction_validation.png` - true $E$ vs 50 Hz apparent $E$ vs Kelvin-Voigt fit
- `shear_wave_dispersion_curves.png` - theory, unwrapped and wrapped estimates
- `phase_unwrapping.png` - wrapped vs unwrapped $\Delta\phi(f)$
- `distal_snr_vs_frequency.png` - why the sweep is attenuation-limited

---

## How to Run
```matlab
cd('10_Shear_Wave_Dispersion_and_Modulus')
experiment_shear_wave            % or run master_run_all from the suite root
```
Figures are written to `outputs/10_Shear_Wave_Dispersion_and_Modulus/` (git-ignored).
