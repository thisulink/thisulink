# Experiment 06: Sensor Noise Floor & SNR Robustness Analysis

## 1. Rationale & Environmental Noise Rejection
Plantar skin can be hyperkeratotic (thickened callus) in diabetic individuals, attenuating acoustic signals before reaching surface sensors. Furthermore, clinical triage occurs in community health centers and rural camps where electrical and vibrational ambient noise may exist.

This experiment sweeps sensor noise density across six orders of magnitude (from $10\ \mu\text{g}/\sqrt{\text{Hz}}$ to $8000\ \mu\text{g}/\sqrt{\text{Hz}}$) to prove that the Analog Devices ADXL355 ($25\ \mu\text{g}/\sqrt{\text{Hz}}$) maintains exceptional signal fidelity and sub-degree phase tracking accuracy.

---

## 2. Signal-to-Noise Ratio (SNR) Formulation
$$\text{SNR}_{\text{dB}} = 20 \log_{10}\left(\frac{\text{RMS}_{\text{signal}}}{\text{RMS}_{\text{error}}}\right)$$

Phase tracking accuracy at the diagnostic fundamental:
$$\Delta \phi_{\text{error}} = |\phi_{\text{measured}} - \phi_{\text{ground\_truth}}|$$

---

## 3. Results (simulation, distal pickup, Class 1, 50 Hz)
Numbers below are the console output of the script (GNU Octave 11.3 run of `master_run_all`). Synthetic noise comes from `common/det_randn.m`, so MATLAB prints the same values; ODE-based values can differ in the last digit between MATLAB and Octave.

| Noise density (m/s²/√Hz) | ≈ µg/√Hz | Broadband SNR | Detected f | Phase error |
|---|---|---|---|---|
| 0.000100 | 10 | 21.9 dB | 50 Hz | 0.03° |
| **0.000245 (ADXL355)** | **25** | **18.2 dB** | **50 Hz** | **0.11°** |
| 0.001000 | 102 | 7.2 dB | 50 Hz | 0.06° |
| 0.005000 | 510 | -6.5 dB | 50 Hz | 2.6° |
| 0.020000 | 2039 | -18.6 dB | 50 Hz | 3.5° |
| 0.080000 | 8158 | -30.6 dB | 208 Hz (lost) | 48° |

- At the ADXL355 noise floor the 50 Hz phase error is ~0.1°, well below a 1° budget; phase tracking only degrades at ~20x the ADXL355 noise density.
- Broadband SNR is below 20 dB even for the nominal sensor, because the signal at 145 mm is small (see Experiment 05). The phase estimate is not limited by this because it averages coherently. Single noise realisation per level, so the phase-error column is not monotonic.

## 4. Limitations
- One noise realisation per level; no ambient vibration, cable or callus modelling.

## 5. Generated Figures
- `snr_vs_noise.png`, `phase_error_vs_noise.png`, `detected_frequency_vs_noise.png`

---

## How to Run
```matlab
cd('06_Noise_SNR_Analysis')
experiment_noise_snr            % or run master_run_all from the suite root
```
Figures are written to `outputs/06_Noise_SNR_Analysis/` (git-ignored).
