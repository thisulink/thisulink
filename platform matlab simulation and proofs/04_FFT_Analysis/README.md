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

## 3. Results Summary
- **Extracted Fundamental**: $50.0\text{ Hz}$ with amplitude $\approx 2.76\text{ m/s}^2$.
- **2nd Harmonic ($100\text{ Hz}$)**: $< 0.096\text{ m/s}^2$ ($3.5\%$).
- **3rd Harmonic ($150\text{ Hz}$)**: $< 0.033\text{ m/s}^2$ ($1.2\%$).
- **Total Harmonic Distortion**: $\text{THD} \approx 3.7\% \ll 5\%$ clinical threshold, confirming excellent sinusoidal fidelity and phase stability.

---

## 4. Generated Artifacts
- `results/steady_state_acceleration.png`: 600 ms steady-state temporal trace.
- `results/acceleration_fft_spectrum.png`: Amplitude spectrum ($0 - 250\text{ Hz}$) with fundamental and harmonic markers.
