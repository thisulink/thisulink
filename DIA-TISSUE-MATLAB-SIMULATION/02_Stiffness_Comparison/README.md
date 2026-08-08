# Experiment 2 — Tissue Stiffness Comparison

## 1. Aim

To investigate the effect of controlled changes in mechanical stiffness on the simulated acceleration response of the DIA-TISSUE mass-spring-damper system.

Three mechanical models are compared under the same excitation conditions:

- Model A — Compliant
- Model B — Moderately Increased Stiffness
- Model C — Substantially Increased Stiffness

Note: These models represent controlled mechanical-property variations only and are NOT clinical tissue or disease-stage classifications.

---

## 2. Objective

The objectives of this experiment are:

1. To simulate three mechanical models with different stiffness values.
2. To keep the effective mass and damping coefficient controlled.
3. To calculate the theoretical natural frequency of each model.
4. To compare peak acceleration between the models.
5. To compare RMS acceleration between the models.
6. To observe how increasing stiffness changes the mechanical response.

---

## 3. Theory

The mechanical system is represented using the lumped mass-spring-damper equation:

m*x'' + c*x' + k*x = F(t)

where:

m  = effective mass (kg)

c  = damping coefficient (N*s/m)

k  = mechanical stiffness (N/m)

x  = displacement (m)

x' = velocity (m/s)

x'' = acceleration (m/s^2)

F(t) = applied excitation force (N)

The applied excitation is:

F(t) = F0*sin(2*pi*f*t)

---

## 4. Natural Frequency

The theoretical natural frequency is calculated using:

fn = (1/(2*pi))*sqrt(k/m)

Therefore, increasing stiffness while keeping mass constant increases the theoretical natural frequency.

---

## 5. Damping Ratio

The damping ratio is:

zeta = c/(2*sqrt(k*m))

The damping coefficient is kept constant at:

c = 2.00 N*s/m

Therefore, the damping ratio changes as the stiffness changes.

---

## 6. Common Simulation Parameters

| Parameter | Value | Unit |
|---|---:|---|
| Effective mass | 0.0200 | kg |
| Excitation frequency | 30.0 | Hz |
| Force amplitude | 0.100 | N |
| Damping coefficient | 2.00 | N*s/m |

---

## 7. Model Parameters

| Model | Description | Stiffness (N/m) | Damping (N*s/m) | Natural Frequency (Hz) | Damping Ratio |
|---|---|---:|---:|---:|---:|
| A | Compliant | 800.0 | 2.00 | 31.83 | 0.250 |
| B | Moderately Increased Stiffness | 1400.0 | 2.00 | 42.11 | 0.189 |
| C | Substantially Increased Stiffness | 2200.0 | 2.00 | 52.79 | 0.151 |

---

## 8. Model A — Compliant

Stiffness:

k = 800.0 N/m

Natural frequency:

fn = 31.83 Hz

Peak acceleration:

9.1649 m/s^2

RMS acceleration:

6.3889 m/s^2

---

## 9. Model B — Moderately Increased Stiffness

Stiffness:

k = 1400.0 N/m

Natural frequency:

fn = 42.11 Hz

Peak acceleration:

5.5696 m/s^2

RMS acceleration:

3.2088 m/s^2

---

## 10. Model C — Substantially Increased Stiffness

Stiffness:

k = 2200.0 N/m

Natural frequency:

fn = 52.79 Hz

Peak acceleration:

3.6542 m/s^2

RMS acceleration:

1.6570 m/s^2

---

## 11. Experimental Output

The MATLAB simulation produced the following results:

| Model | Stiffness (N/m) | Natural Frequency (Hz) | Peak Acceleration (m/s^2) | RMS Acceleration (m/s^2) |
|---|---:|---:|---:|---:|
| Model A | 800.0 | 31.83 | 9.1649 | 6.3889 |
| Model B | 1400.0 | 42.11 | 5.5696 | 3.2088 |
| Model C | 2200.0 | 52.79 | 3.6542 | 1.6570 |

Excitation frequency:

30.00 Hz

---

## 12. Graphical Results

The MATLAB-generated graphs are available in the results folder.

### Graph 1 — Stiffness vs Displacement Response

File:

results/stiffness_displacement.png

This graph compares the displacement responses of Models A, B, and C under the same excitation.

### Graph 2 — Stiffness vs Acceleration Response

File:

results/stiffness_acceleration.png

This graph compares the acceleration responses of the three mechanical models.

### Graph 3 — Natural Frequency Comparison

File:

results/natural_frequency_comparison.png

This graph compares the theoretical natural frequencies of Models A, B, and C.

### Graph 4 — RMS Acceleration Comparison

File:

results/rms_acceleration_comparison.png

This graph compares the RMS acceleration values obtained from the three models.

---

## 13. Results Folder

The generated MATLAB graphs are stored in:

02_Stiffness_Comparison/results/

| File | Description |
|---|---|
| stiffness_displacement.png | Displacement comparison |
| stiffness_acceleration.png | Acceleration comparison |
| natural_frequency_comparison.png | Natural frequency comparison |
| rms_acceleration_comparison.png | RMS acceleration comparison |

---

## 14. Observation

The stiffness of the three models increases from:

800 N/m → 1400 N/m → 2200 N/m

As stiffness increases, the theoretical natural frequency also increases:

31.83 Hz → 42.11 Hz → 52.79 Hz

At the fixed excitation frequency of 30 Hz, the simulated peak acceleration decreases:

9.1649 m/s^2 → 5.5696 m/s^2 → 3.6542 m/s^2

Similarly, the RMS acceleration decreases:

6.3889 m/s^2 → 3.2088 m/s^2 → 1.6570 m/s^2

Thus, the simulated mechanical response is sensitive to changes in stiffness.

---

## 15. Result

The stiffness comparison experiment was successfully simulated for three controlled mechanical models.

The results demonstrate that changing the stiffness while maintaining the effective mass, damping coefficient, excitation frequency, and force amplitude changes both the theoretical natural frequency and the measured simulated acceleration response.

Model A produced the highest acceleration response at the selected 30 Hz excitation condition, while Model C produced the lowest response.

---

## 16. Inference

The simulation indicates that mechanical stiffness can significantly influence the acceleration response of the DIA-TISSUE mechanical model.

The natural frequency shifts to higher frequencies as stiffness increases.

The results therefore establish a theoretical basis for investigating whether vibration/acceleration-based features can distinguish controlled mechanical-property variations.

These results are engineering simulation results and do not establish clinical tissue classification.

---

## 17. Limitations

1. The three models are simplified lumped mechanical representations.
2. The stiffness values are assumed simulation parameters.
3. The models do not represent specific clinical disease stages.
4. Biological tissue is nonlinear and heterogeneous.
5. Real tissue properties may vary with frequency, strain, temperature, and contact conditions.
6. The simulation does not include experimentally measured tissue data.
7. The acceleration differences observed in simulation require experimental validation.
8. Sensor noise, contact-force variation, and actuator characteristics are studied separately in later experiments.

---

## 18. Conclusion

The DIA-TISSUE stiffness comparison simulation was successfully performed using three controlled mechanical models.

The stiffness was increased from 800 N/m to 1400 N/m and finally to 2200 N/m.

The corresponding theoretical natural frequency increased from 31.83 Hz to 42.11 Hz and 52.79 Hz.

At a fixed excitation frequency of 30 Hz, the peak acceleration decreased from 9.1649 m/s^2 for Model A to 5.5696 m/s^2 for Model B and 3.6542 m/s^2 for Model C.

The RMS acceleration similarly decreased from 6.3889 m/s^2 to 3.2088 m/s^2 and 1.6570 m/s^2.

Therefore, the simulation demonstrates a measurable relationship between controlled mechanical stiffness and acceleration response.

---

## 19. Repository Structure

02_Stiffness_Comparison/

    experiment_stiffness.m

    README.md

    results/
        stiffness_displacement.png
        stiffness_acceleration.png
        natural_frequency_comparison.png
        rms_acceleration_comparison.png

Common project files:

common/

    simulation_parameters.m

    tissue_model.m

---

## 20. Simulation Disclaimer

This experiment is an engineering simulation.

The stiffness values, mass, damping, excitation, and force values are simulation assumptions.

Models A, B, and C represent controlled mechanical-property variations only.

The results must not be interpreted as clinical measurements, diagnostic thresholds, or disease-stage classifications.