# Experiment 4 - FFT Analysis

## 1. Aim

To perform Fast Fourier Transform (FFT) analysis on the simulated steady-state acceleration signal of the DIA-TISSUE mechanical model and determine whether the known excitation frequency can be identified from the frequency spectrum.

Note: This experiment is an engineering simulation. The parameters are simulation assumptions and are not clinical values.

## 2. Objective

The objectives of this experiment are:

1. To generate a simulated acceleration signal for Model A.
2. To perform FFT analysis on the acceleration signal.
3. To identify the dominant frequency component.
4. To compare the detected FFT frequency with the known excitation frequency.
5. To determine the frequency resolution of the FFT.
6. To visualize the steady-state acceleration and its frequency spectrum.

## 3. Theory

The DIA-TISSUE mechanical system is represented using a lumped mass-spring-damper model.

The governing equation is:

m*x'' + c*x' + k*x = F(t)

where:

m = effective mass (kg)
c = damping coefficient (N*s/m)
k = stiffness (N/m)
x = displacement (m)
x' = velocity (m/s)
x'' = acceleration (m/s^2)
F(t) = applied force (N)

The applied excitation is sinusoidal:

F(t) = F0*sin(2*pi*f*t)

where:

F0 = force amplitude (N)
f = excitation frequency (Hz)

For harmonic excitation:

w = 2*pi*f

The mechanical dynamic stiffness is:

D(jw) = (k - m*w^2) + j*c*w

The complex displacement response is:

X = F0 / D(jw)

The acceleration response is obtained from:

A = -w^2*X

The FFT converts the time-domain acceleration signal into its frequency-domain representation.

## 4. FFT Processing

The FFT processing used in this experiment consists of:

1. Conversion of the input signal into a column vector.
2. Removal of the DC component.
3. Application of a Hann window.
4. Calculation of the FFT.
5. Correction using the coherent gain of the Hann window.
6. Conversion to a single-sided magnitude spectrum.
7. Generation of the frequency axis.
8. Identification of the dominant spectral component.

The frequency resolution is calculated as:

Frequency Resolution = fs/N

where:

fs = sampling frequency (Hz)
N = number of samples used for FFT analysis

## 5. Simulation Parameters

| Parameter | Symbol | Value | Unit |
|---|---|---:|---|
| Effective mass | m | 0.0200 | kg |
| Excitation frequency | f | 30.00 | Hz |
| Force amplitude | F0 | 0.100 | N |
| Model | - | A - Compliant | - |
| Stiffness | k | 800.0 | N/m |
| Damping coefficient | c | 2.00 | N*s/m |
| Sampling frequency | fs | 4000.00 | Hz |
| FFT simulation duration | T | 2.0 | s |

## 6. Model Parameters

### Model A - Compliant

| Parameter | Value |
|---|---:|
| Mass | 0.0200 kg |
| Stiffness | 800.0 N/m |
| Damping | 2.00 N*s/m |
| Natural frequency | 31.83 Hz |
| Damping ratio | 0.250 |
| Excitation frequency | 30.00 Hz |

## 7. MATLAB Files

The experiment uses:

04_FFT_Analysis/experiment_fft.m

04_FFT_Analysis/fft_analysis.m

Common files:

common/simulation_parameters.m

common/tissue_model.m

The common files are not modified by this experiment.

## 8. Simulation Procedure

1. Load the common simulation parameters.
2. Select Model A.
3. Set the local FFT sampling frequency to 4000 Hz.
4. Generate the local FFT time vector.
5. Calculate the steady-state mechanical response.
6. Generate the acceleration signal.
7. Remove the DC component during FFT processing.
8. Apply a Hann window.
9. Calculate the FFT.
10. Generate the single-sided frequency spectrum.
11. Search for the maximum spectral magnitude after ignoring the DC component.
12. Identify the dominant frequency.
13. Generate the acceleration and FFT graphs.

## 9. Actual MATLAB Output

The simulation was successfully executed.

Model:

A - Compliant

Excitation frequency:

30.00 Hz

Sampling frequency:

4000.00 Hz

### FFT Results

Expected excitation frequency:

30.00 Hz

Dominant FFT frequency:

30.00 Hz

FFT peak magnitude:

9.1705 m/s^2

Frequency resolution:

0.5000 Hz

## 10. Results Table

| Quantity | Result | Unit |
|---|---:|---|
| Model | A - Compliant | - |
| Excitation frequency | 30.00 | Hz |
| Sampling frequency | 4000.00 | Hz |
| Expected excitation frequency | 30.00 | Hz |
| Dominant FFT frequency | 30.00 | Hz |
| FFT peak magnitude | 9.1705 | m/s^2 |
| Frequency resolution | 0.5000 | Hz |

## 11. Graphical Results

The MATLAB-generated graphs are available in the results folder.

### Graph 1 - Steady-State Acceleration

File:

results/steady_state_acceleration.png

This graph shows the simulated steady-state acceleration signal in the time domain.

### Graph 2 - Acceleration FFT Spectrum

File:

results/acceleration_fft_spectrum.png

This graph shows the single-sided FFT magnitude spectrum of the acceleration signal.

The expected 30 Hz excitation frequency is marked on the FFT spectrum.

## 12. Results Folder

The generated graph files are stored in:

04_FFT_Analysis/results/

| File | Description |
|---|---|
| steady_state_acceleration.png | Steady-state acceleration waveform |
| acceleration_fft_spectrum.png | Acceleration FFT magnitude spectrum |

## 13. Observation

The known excitation frequency applied to the Model A mechanical system is 30.00 Hz.

The FFT analysis identified the dominant spectral frequency as 30.00 Hz.

Therefore:

Expected frequency = 30.00 Hz

Detected frequency = 30.00 Hz

The detected frequency exactly matches the known excitation frequency in the simulation.

The FFT peak magnitude was 9.1705 m/s^2.

The frequency resolution of the FFT was 0.5000 Hz.

## 14. Result

FFT analysis of the simulated acceleration signal was successfully performed.

The expected excitation frequency of 30.00 Hz was correctly identified as the dominant FFT frequency.

The FFT peak magnitude was 9.1705 m/s^2 and the frequency resolution was 0.5000 Hz.

Therefore, the simulated signal-processing chain successfully recovered the known excitation frequency from the acceleration signal.

## 15. Inference

The experiment demonstrates that FFT analysis can extract the dominant excitation frequency from the simulated mechanical acceleration signal.

The exact match between the expected 30 Hz excitation and the detected 30 Hz FFT peak confirms that the frequency-domain processing is functioning correctly for this simulated condition.

This establishes FFT-based frequency extraction as a useful engineering feature for subsequent DIA-TISSUE signal analysis.

This result does not establish clinical tissue classification or diagnosis.

## 16. Limitations

1. The acceleration signal is simulated rather than experimentally measured.
2. The mechanical parameters are assumed simulation values.
3. The experiment uses Model A only.
4. The excitation frequency is already known in the simulation.
5. The FFT result does not by itself demonstrate tissue classification.
6. Real sensor measurements will contain noise, bias, quantization effects, and other disturbances.
7. Real biological tissue may exhibit nonlinear and frequency-dependent behavior.
8. Experimental validation is required before applying the method to physical measurements.

## 17. Conclusion

The DIA-TISSUE FFT analysis experiment was successfully completed using the Model A compliant mechanical condition.

A 30.00 Hz sinusoidal excitation was applied to the simulated mechanical system and the resulting acceleration signal was analyzed using FFT.

The dominant FFT frequency was found to be 30.00 Hz, exactly matching the expected excitation frequency.

The FFT peak magnitude was 9.1705 m/s^2 and the frequency resolution was 0.5000 Hz.

The experiment confirms the ability of the implemented FFT processing method to identify the dominant frequency component of the simulated acceleration signal.

## 18. Repository Structure

04_FFT_Analysis/

    experiment_fft.m

    fft_analysis.m

    README.md

    results/

        steady_state_acceleration.png

        acceleration_fft_spectrum.png

Common project files:

common/

    simulation_parameters.m

    tissue_model.m

## 19. Simulation Disclaimer

This experiment is an engineering simulation.

All mechanical, excitation, sampling, and signal-processing parameters are simulation assumptions unless explicitly stated otherwise.

The results must not be interpreted as clinical measurements, diagnostic thresholds, or disease-stage classifications.