# Experiment 6 - Noise / SNR Analysis

## 1. Aim

To investigate the effect of different sensor noise-density levels on the measurement error, signal-to-noise ratio (SNR), and detected excitation frequency of the DIA-TISSUE simulated acceleration signal.

Note: This experiment is an engineering simulation. The parameters and results are NOT clinical values.

## 2. Objective

The objectives of this experiment are:

1. To generate the true acceleration response of Model A.
2. To introduce different levels of simulated sensor noise.
3. To calculate the measurement error RMS for each noise level.
4. To calculate the corresponding SNR.
5. To determine whether the excitation frequency can still be detected under increasing noise.
6. To compare the effect of sensor noise on signal quality.

## 3. Theory

Sensor noise can affect the accuracy of mechanical vibration measurements.

The simulated measured acceleration can be represented as:

a_measured = a_true + bias + noise

where:

a_true = true acceleration signal

bias = sensor bias

noise = simulated random sensor noise

The RMS noise is estimated from:

Noise RMS = Noise Density * sqrt(Bandwidth)

The measurement error is calculated as:

Error RMS = RMS(a_measured - a_true)

The signal-to-noise ratio is calculated using:

SNR(dB) = 20*log10(True Signal RMS / Error RMS)

A higher SNR indicates a stronger signal relative to the measurement error.

FFT analysis is also performed to determine whether the known excitation frequency can still be detected as the dominant frequency component.

## 4. Simulation Parameters

| Parameter | Value | Unit |
|---|---:|---|
| Effective mass | 0.0200 | kg |
| Excitation frequency | 30.0 | Hz |
| Force amplitude | 0.100 | N |
| Model | Model A - Compliant | - |
| Stiffness | 800.0 | N/m |
| Damping coefficient | 2.00 | N*s/m |
| Sensor bandwidth | 150.0 | Hz |
| Sensor bias | 0.010000 | m/s^2 |

## 5. Noise Density Levels

The following noise-density values were evaluated:

| Noise Density | Unit |
|---:|---|
| 0.000250 | m/s^2/sqrt(Hz) |
| 0.001000 | m/s^2/sqrt(Hz) |
| 0.005000 | m/s^2/sqrt(Hz) |
| 0.010000 | m/s^2/sqrt(Hz) |
| 0.050000 | m/s^2/sqrt(Hz) |
| 0.100000 | m/s^2/sqrt(Hz) |

## 6. MATLAB Files

The experiment uses:

06_Noise_SNR_Analysis/experiment_noise_snr.m

Common files:

common/simulation_parameters.m

common/tissue_model.m

The common files are not modified by this experiment.

## 7. Simulation Procedure

1. Load the common DIA-TISSUE simulation parameters.
2. Select Model A.
3. Generate the true mechanical acceleration signal.
4. Calculate the true acceleration RMS.
5. Define multiple sensor noise-density levels.
6. Generate simulated random noise for each noise-density level.
7. Add the simulated sensor bias and noise to the true acceleration.
8. Calculate the measurement error RMS.
9. Calculate the SNR in dB.
10. Perform FFT analysis on the noisy signal.
11. Detect the dominant frequency.
12. Compare the detected frequency with the known 30 Hz excitation.
13. Generate the result graphs.

## 8. Actual MATLAB Output

True acceleration RMS:

6.388942 m/s^2

The MATLAB simulation produced the following results:

| Noise Density (m/s^2/sqrt(Hz)) | Error RMS (m/s^2) | SNR (dB) | Detected Frequency (Hz) |
|---:|---:|---:|---:|
| 0.000250 | 0.010501 | 55.68 | 30.00 |
| 0.001000 | 0.015659 | 52.21 | 30.00 |
| 0.005000 | 0.062666 | 40.17 | 30.00 |
| 0.010000 | 0.122869 | 34.33 | 30.00 |
| 0.050000 | 0.609096 | 20.41 | 30.00 |
| 0.100000 | 1.227085 | 14.33 | 30.00 |

## 9. Detailed Output

### Noise Density = 0.000250 m/s^2/sqrt(Hz)

Error RMS = 0.010501 m/s^2

SNR = 55.68 dB

Detected frequency = 30.00 Hz

### Noise Density = 0.001000 m/s^2/sqrt(Hz)

Error RMS = 0.015659 m/s^2

SNR = 52.21 dB

Detected frequency = 30.00 Hz

### Noise Density = 0.005000 m/s^2/sqrt(Hz)

Error RMS = 0.062666 m/s^2

SNR = 40.17 dB

Detected frequency = 30.00 Hz

### Noise Density = 0.010000 m/s^2/sqrt(Hz)

Error RMS = 0.122869 m/s^2

SNR = 34.33 dB

Detected frequency = 30.00 Hz

### Noise Density = 0.050000 m/s^2/sqrt(Hz)

Error RMS = 0.609096 m/s^2

SNR = 20.41 dB

Detected frequency = 30.00 Hz

### Noise Density = 0.100000 m/s^2/sqrt(Hz)

Error RMS = 1.227085 m/s^2

SNR = 14.33 dB

Detected frequency = 30.00 Hz

## 10. Graphical Results

The MATLAB-generated graphs are available in the results folder.

### Graph 1 - Measurement Error vs Noise

File:

results/measurement_error_vs_noise.png

This graph shows the increase in measurement error RMS as the sensor noise density increases.

### Graph 2 - SNR vs Noise

File:

results/snr_vs_noise.png

This graph shows the decrease in SNR as sensor noise density increases.

### Graph 3 - Detected Frequency vs Noise

File:

results/detected_frequency_vs_noise.png

This graph shows the detected dominant frequency for each noise-density level.

## 11. Results Folder

The generated graph files are stored in:

06_Noise_SNR_Analysis/results/

| File | Description |
|---|---|
| measurement_error_vs_noise.png | Measurement error versus noise density |
| snr_vs_noise.png | SNR versus noise density |
| detected_frequency_vs_noise.png | Detected frequency versus noise density |

## 12. Observation

The true acceleration RMS of the simulated Model A signal was:

6.388942 m/s^2

As the sensor noise density increased, the measurement error RMS increased.

The error RMS increased from:

0.010501 m/s^2

at 0.000250 m/s^2/sqrt(Hz)

to:

1.227085 m/s^2

at 0.100000 m/s^2/sqrt(Hz).

At the same time, the SNR decreased from:

55.68 dB

to:

14.33 dB.

Despite the increase in noise, the detected dominant frequency remained:

30.00 Hz

for all six tested noise-density levels.

## 13. Result

The noise and SNR analysis was successfully performed for six different sensor noise-density levels.

The results show that increasing noise density increases measurement error and reduces SNR.

The SNR decreased progressively from 55.68 dB to 14.33 dB as the noise density increased.

The 30 Hz excitation frequency remained detectable in all tested simulation conditions.

## 14. Inference

The simulation demonstrates that sensor noise has a direct effect on measurement quality.

Increasing noise density results in:

- Increased measurement error
- Reduced SNR
- Reduced signal quality

However, under the tested simulation conditions, the dominant excitation frequency remained detectable at 30 Hz even at the highest simulated noise density of 0.100000 m/s^2/sqrt(Hz).

This indicates that frequency-domain analysis can remain useful even when measurement noise increases, within the conditions tested in this simulation.

The result does not establish clinical sensor performance or clinical diagnostic capability.

## 15. Limitations

1. The acceleration signal is simulated rather than experimentally measured.
2. The noise-density values are assumed simulation parameters.
3. The noise model uses simulated random noise.
4. Real sensor noise may have frequency-dependent characteristics.
5. Environmental vibration and electromagnetic interference are not modeled.
6. Sensor mounting effects are not included.
7. The experiment uses Model A only.
8. The detected frequency is based on a known simulated excitation.
9. Real biological tissue may introduce additional mechanical variability.
10. Experimental hardware validation is required.

## 16. Conclusion

The DIA-TISSUE noise and SNR analysis was successfully performed using six different simulated sensor noise-density levels.

The true acceleration RMS was 6.388942 m/s^2.

As noise density increased from 0.000250 to 0.100000 m/s^2/sqrt(Hz), the measurement error increased from 0.010501 m/s^2 to 1.227085 m/s^2.

The SNR decreased from 55.68 dB to 14.33 dB.

The detected excitation frequency remained at 30.00 Hz for all tested noise levels.

Therefore, the experiment demonstrates the relationship between sensor noise, measurement error, SNR, and frequency detection in the simulated DIA-TISSUE system.

## 17. Repository Structure

06_Noise_SNR_Analysis/

    experiment_noise_snr.m

    README.md

    results/

        measurement_error_vs_noise.png

        snr_vs_noise.png

        detected_frequency_vs_noise.png

Common project files:

common/

    simulation_parameters.m

    tissue_model.m

## 18. Simulation Disclaimer

This experiment is an engineering simulation.

All mechanical, sensor, noise, and signal-processing parameters are simulation assumptions unless explicitly stated otherwise.

The results must not be interpreted as clinical measurements, diagnostic thresholds, or disease-stage classifications.