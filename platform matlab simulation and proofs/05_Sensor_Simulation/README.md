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
- **Internal Filter Bandwidth**: $150\text{ Hz}$
- **Integrated RMS Noise Floor**: $\sigma_n = 25 \times 10^{-6} \times 9.80665 \times \sqrt{150} \approx 0.0030\text{ m/s}^2$

---

## 3. Findings & Performance
- **Proximal Pickup SNR**: $\approx 51.4\text{ dB}$ (Signal RMS $\approx 0.95\text{ m/s}^2$, Error RMS $\approx 0.0026\text{ m/s}^2$).
- **Distal Pickup SNR**: $\approx 47.8\text{ dB}$ (Signal RMS $\approx 0.63\text{ m/s}^2$).
- **Time-of-Flight (ToF)**: Wave arrives at Distal Sensor 2 with $\approx 10.75\text{ ms}$ delay relative to Sensor 1 in healthy tissue ($c_s = 3.72\text{ m/s}$), providing sharp, easily resolvable phase tracking.

---

## 4. Generated Artifacts
- `results/dual_adxl355_waveforms.png`: Proximal vs distal wave capture showing clear time delay $\Delta t$.
- `results/measurement_error.png`: Residual digitization and Gaussian noise residuals.
