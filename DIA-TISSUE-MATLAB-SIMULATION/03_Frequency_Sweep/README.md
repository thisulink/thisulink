# Experiment 3 — Frequency Response Sweep

## 1. Aim

To investigate the frequency-dependent mechanical response of the DIA-TISSUE system by performing a controlled excitation frequency sweep from 10 Hz to 500 Hz for three mechanical models with different stiffness values.

The experiment is used to determine the frequency at which the acceleration response reaches its maximum value for each model.

Note: The values used in this experiment are simulation assumptions and are NOT clinical values.

---

## 2. Objective

The objectives of this experiment are:

1. To perform a theoretical frequency sweep from 10 Hz to 500 Hz.
2. To use a frequency step of 1 Hz.
3. To evaluate the acceleration response of Models A, B, and C.
4. To determine the peak acceleration frequency for each model.
5. To compare the peak response frequency with the theoretical natural frequency.
6. To study the shift in frequency response caused by changes in stiffness.

---

## 3. Theory

The DIA-TISSUE mechanical system is represented by a lumped mass-spring-damper model:

m*x'' + c*x' + k*x = F(t)

where:

m  = effective mass (kg)

c  = damping coefficient (N*s/m)

k  = stiffness (N/m)

x  = displacement (m)

x' = velocity (m/s)

x'' = acceleration (m/s^2)

F(t) = applied excitation force (N)

For sinusoidal excitation:

F(t) = F0*sin(2*pi*f*t)

where:

F0 = force amplitude

f = excitation frequency

---

## 4. Natural Frequency

The theoretical natural frequency is:

fn = (1/(2*pi))*sqrt(k/m)

As stiffness increases while mass remains constant, the natural frequency increases.

---

## 5. Frequency Response

For harmonic excitation, the mechanical displacement frequency response can be represented by:

H_x(jw) = 1/(k - m*w^2 + j*c*w)

where:

w = 2*pi*f

The displacement amplitude is:

|X| = |H_x|*F0

The acceleration amplitude is calculated from:

|A| = w^2*|X|

The simulation evaluates this response for every frequency from 10 Hz to 500 Hz.

---

## 6. Simulation Parameters

| Parameter | Value | Unit |
|---|---:|---|
| Effective mass | 0.0200 | kg |
| Excitation force amplitude | 0.100 | N |
| Frequency start | 10.0 | Hz |
| Frequency end | 500.0 | Hz |
| Frequency step | 1.0 | Hz |
| Number of frequency points | 491 | — |

---

## 7. Mechanical Models

| Model | Description | Stiffness (N/m) | Damping (N*s/m) | Natural Frequency (Hz) | Damping Ratio |
|---|---|---:|---:|---:|---:|
| A | Compliant | 800.0 | 2.00 | 31.83 | 0.250 |
| B | Moderately Increased Stiffness | 1400.0 | 2.00 | 42.11 | 0.189 |
| C | Substantially Increased Stiffness | 2200.0 | 2.00 | 52.79 | 0.151 |

---

## 8. Frequency Sweep Configuration

The frequency sweep was performed using:

Frequency range:

10.0 Hz to 500.0 Hz

Frequency step:

1.0 Hz

Number of points:

491

The simulation evaluates the acceleration response independently at each frequency point.

---

## 9. Experimental Output

### Model A — Compliant

Stiffness:

800.0 N/m

Theoretical natural frequency:

31.83 Hz

Peak acceleration frequency:

34.00 Hz

Peak acceleration:

10.3279 m/s^2

---

### Model B — Moderately Increased Stiffness

Stiffness:

1400.0 N/m

Theoretical natural frequency:

42.11 Hz

Peak acceleration frequency:

44.00 Hz

Peak acceleration:

13.4636 m/s^2

---

### Model C — Substantially Increased Stiffness

Stiffness:

2200.0 N/m

Theoretical natural frequency:

52.79 Hz

Peak acceleration frequency:

54.00 Hz

Peak acceleration:

16.7748 m/s^2

---

## 10. Results Table

| Model | Stiffness (N/m) | Theoretical Natural Frequency (Hz) | Peak Acceleration Frequency (Hz) | Peak Acceleration (m/s^2) |
|---|---:|---:|---:|---:|
| Model A | 800.0 | 31.83 | 34.00 | 10.3279 |
| Model B | 1400.0 | 42.11 | 44.00 | 13.4636 |
| Model C | 2200.0 | 52.79 | 54.00 | 16.7748 |

---

## 11. Graphical Results

The MATLAB-generated graphs are available in the results folder.

### Graph 1 — Acceleration Frequency Response

File:

results/acceleration_frequency_response.png

This graph shows acceleration amplitude as a function of excitation frequency for Models A, B, and C.

The graph allows comparison of the frequency-dependent acceleration response and the location of the maximum response.

---

### Graph 2 — Displacement Frequency Response

File:

results/displacement_frequency_response.png

This graph shows the displacement amplitude as a function of excitation frequency for the three mechanical models.

---

### Graph 3 — Phase Response

File:

results/phase_response.png

This graph shows the phase response of the mechanical system relative to the applied excitation force.

---

## 12. Results Folder

The generated MATLAB graphs are stored in:

03_Frequency_Sweep/results/

| File | Description |
|---|---|
| acceleration_frequency_response.png | Acceleration frequency response |
| displacement_frequency_response.png | Displacement frequency response |
| phase_response.png | Phase response |

---

## 13. Observation

The frequency sweep shows that the peak acceleration response occurs at different frequencies for the three models.

For Model A:

Theoretical natural frequency = 31.83 Hz

Peak acceleration frequency = 34.00 Hz

For Model B:

Theoretical natural frequency = 42.11 Hz

Peak acceleration frequency = 44.00 Hz

For Model C:

Theoretical natural frequency = 52.79 Hz

Peak acceleration frequency = 54.00 Hz

As stiffness increases, both the theoretical natural frequency and the observed peak acceleration frequency shift toward higher frequencies.

The peak acceleration values obtained from the frequency sweep also increase from Model A to Model C under this particular frequency-response calculation.

---

## 14. Result

The frequency response sweep was successfully performed over the range of 10 Hz to 500 Hz with a 1 Hz frequency step.

The peak acceleration frequencies obtained were:

Model A = 34.00 Hz

Model B = 44.00 Hz

Model C = 54.00 Hz

The corresponding peak acceleration values were:

Model A = 10.3279 m/s^2

Model B = 13.4636 m/s^2

Model C = 16.7748 m/s^2

The simulation demonstrates that changes in mechanical stiffness produce a measurable shift in the frequency response of the system.

---

## 15. Inference

The frequency sweep provides an important frequency-domain feature for the DIA-TISSUE simulation.

The peak response frequency shifts upward as the stiffness increases:

34 Hz → 44 Hz → 54 Hz

This indicates that frequency-response characteristics can be used as an engineering feature for distinguishing controlled mechanical-property variations in the simulated models.

The result supports further investigation using frequency-domain and signal-processing techniques.

These results are simulation findings and do not establish clinical tissue classification.

---

## 16. Limitations

1. The frequency sweep is a theoretical simulation.
2. The stiffness and damping values are assumed parameters.
3. The three models represent controlled mechanical-property variations only.
4. The models do not represent specific disease stages.
5. Real biological tissue has nonlinear and frequency-dependent mechanical behavior.
6. The simulation does not include experimentally measured tissue properties.
7. The frequency range is a theoretical analysis range and does not establish the usable frequency range of the final physical actuator.
8. Experimental hardware validation is required before drawing conclusions from real tissue measurements.

---

## 17. Conclusion

A frequency response sweep was successfully performed from 10 Hz to 500 Hz with a 1 Hz frequency resolution.

The theoretical natural frequencies of Models A, B, and C were 31.83 Hz, 42.11 Hz, and 52.79 Hz respectively.

The simulated peak acceleration frequencies were 34 Hz, 44 Hz, and 54 Hz respectively.

The results demonstrate that increasing mechanical stiffness shifts the frequency response toward higher frequencies.

Therefore, the frequency-response peak can serve as a useful engineering feature for subsequent DIA-TISSUE signal-processing and mechanical-property analysis.

---

## 18. Repository Structure

03_Frequency_Sweep/

    experiment_frequency_sweep.m

    README.md

    results/
        acceleration_frequency_response.png
        displacement_frequency_response.png
        phase_response.png

Common project files:

common/

    simulation_parameters.m

    tissue_model.m

---

## 19. Simulation Disclaimer

This experiment is an engineering simulation.

All mass, stiffness, damping, force, and frequency parameters are assumed simulation values unless experimentally measured values are explicitly stated.

Models A, B, and C represent controlled mechanical-property variations only.

The results must not be interpreted as clinical measurements, diagnostic thresholds, or disease-stage classifications.