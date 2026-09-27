# Experiment 05: Dual ADXL355 20-Bit Accelerometer Sensor Simulation

## 1. Hardware Architecture: Dual Pickup Setup
The **THISULINK** platform replaces expensive ultrasound phased-array transducers with dual high-precision triaxial digital accelerometers (Analog Devices ADXL355):
- **Proximal Sensor 1**: Positioned at $x_1 = 105\text{ mm}$ from the actuator contactor tip.
- **Distal Sensor 2**: Positioned at $x_2 = 145\text{ mm}$ from the contactor tip ($\Delta x = 40\text{ mm}$ baseline gauge length).

This dual-sensor configuration captures the propagating shear wave at two distinct spatial locations, allowing real-time estimation of wave speed:
$$c_s = \frac{\Delta x}{\Delta t}$$

---

## 2. Sensor Noise & Digitization Characteristics
The Analog Devices ADXL355 provides:
- **Measurement Range**: $\pm 2.048\text{ g}$ ($\pm 20.08\text{ m/s}^2$)
- **ADC Resolution**: 20-bit $\Sigma\Delta$ ADC
- **Quantization Step**: $q = \frac{2 \times 20.08}{2^{20}} \approx 3.83 \times 10^{-5}\text{ m/s}^2$ ($3.9\ \mu\text{g}$)
- **Noise Spectral Density**: $25\ \mu\text{g}/\sqrt{\text{Hz}} = 0.000245\text{ m/s}^2/\sqrt{\text{Hz}}$
- **Output data rate / filter bandwidth (simulated)**: ODR $4000\text{ Hz}$, digital LPF $\approx$ ODR/4 $= 1000\text{ Hz}$ (the previous $150\text{ Hz}$ was below the $10 - 300\text{ Hz}$ sweep)
- **Integrated RMS Noise Floor**: $\sigma_n = 25 \times 10^{-6} \times 9.80665 \times \sqrt{1000} \approx 0.0077\text{ m/s}^2$

---

## 3. Results (simulation, Class 1 tissue, 50 Hz)
Numbers below are the console output of the script (GNU Octave 11.3 run of `master_run_all`). Synthetic noise comes from `common/det_randn.m`, so MATLAB prints the same values; ODE-based values can differ in the last digit between MATLAB and Octave.

| Pickup | Signal RMS | Error RMS | Broadband SNR (0-1000 Hz) | Narrow-band SNR at 50 Hz |
|---|---|---|---|---|
| Proximal (105 mm) | 0.133 m/s² | 0.0091 m/s² | 23.3 dB | 59.9 dB |
| Distal (145 mm) | 0.074 m/s² | 0.0092 m/s² | 18.1 dB | 54.8 dB |

- Viscoelastic phase velocity at 50 Hz: 3.81 m/s → inter-sensor delay 10.50 ms.
- The broadband SNR is modest because the viscous model attenuates the wave strongly over 105-145 mm. The phase estimator uses coherent averaging at 50 Hz (0.8 s window), where the effective SNR is ~55 dB.
- Earlier README values (47.8-51.4 dB broadband, 0.95 m/s² signal) were not reproducible with the current models.

## 4. Limitations
- White-noise sensor model: RMS = density × √bandwidth, 20-bit quantisation, saturation, fixed bias. The ADXL355 digital filter response is not modelled (identical on both pickups, so it cancels in the phase difference).
- Only the POC firmware exists today and it uses an **ADXL345 at 200 Hz ODR** (Nyquist 100 Hz), which cannot cover the 10-300 Hz sweep; these results assume the production dual-ADXL355 probe.

## 5. Generated Figures
- `dual_adxl355_waveforms.png`, `measurement_error.png`

---

## How to Run
```matlab
cd('05_Sensor_Simulation')
experiment_sensor            % or run master_run_all from the suite root
```
Figures are written to `outputs/05_Sensor_Simulation/` (git-ignored).
