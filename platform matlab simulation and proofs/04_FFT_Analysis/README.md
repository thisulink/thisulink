# Experiment 04: FFT Harmonic Spectrum & Purity Analysis

## 1. Technical Purpose & Signal Integrity
Shear wave elastography phase-difference algorithms rely on clean, single-frequency phase tracking. If non-linear tissue stiffening or voice-coil distortion produces significant harmonic distortion (THD $> 10\%$), phase unwrapping between proximal and distal pickups can incur cycle-skip errors.

This experiment implements an analytical Hann-windowed, coherent-gain normalized Fast Fourier Transform (FFT) to quantify the spectral purity and Total Harmonic Distortion (THD) of the plantar acceleration signal under THISULINK's voice coil actuation.

---

## 2. Mathematical Formulation
The Total Harmonic Distortion (THD) is defined as:
$$\text{THD} = \frac{\sqrt{\sum_{n=2}^{\infty} V_n^2}}{V_1} \times 100\%$$

Where:
- $V_1$ is the fundamental harmonic amplitude at $f_{\text{exc}} = 50.0\text{ Hz}$.
- $V_2, V_3$ are the 2nd and 3rd harmonic amplitudes at $100\text{ Hz}$ and $150\text{ Hz}$.

---

## 3. Results (simulation)
Numbers below are the console output of the script (GNU Octave 11.3 run of `master_run_all`). Synthetic noise comes from `common/det_randn.m`, so MATLAB prints the same values; ODE-based values can differ in the last digit between MATLAB and Octave.

- Fundamental: 50.00 Hz, amplitude 2.65 m/s²
- 2nd harmonic (100 Hz): 0.093 m/s²; 3rd harmonic (150 Hz): 0.032 m/s²
- THD = 3.70 % (-28.6 dB) → passes the 5 % design threshold

## 4. Limitations
- The 3.5 % / 1.2 % harmonic levels are **assumed inputs**. The experiment verifies the Hann-window FFT/THD pipeline (`fft_analysis.m`), it does not predict the distortion of a real actuator or tissue.

## 5. Generated Figures
- `steady_state_acceleration.png`, `acceleration_fft_spectrum.png`

---

## How to Run
```matlab
cd('04_FFT_Analysis')
experiment_fft            % or run master_run_all from the suite root
```
Figures are written to `outputs/04_FFT_Analysis/` (git-ignored).
