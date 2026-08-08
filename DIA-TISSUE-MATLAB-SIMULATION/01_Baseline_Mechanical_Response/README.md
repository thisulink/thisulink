# Experiment 1 — Baseline Mechanical Response

## 1. Aim

To develop and simulate a baseline lumped viscoelastic mass-spring-damper model for the DIA-TISSUE system and study the mechanical response of a compliant tissue model under sinusoidal excitation.

The simulation evaluates displacement, velocity, and acceleration response for a controlled mechanical model.

> Note: All parameters used in this experiment are simulation assumptions and are NOT clinical values.

---

## 2. Objective

The objectives of this experiment are:

1. To implement the baseline mass-spring-damper tissue model.
2. To apply a sinusoidal mechanical excitation.
3. To calculate tissue/probe displacement.
4. To calculate velocity.
5. To calculate acceleration.
6. To obtain peak and RMS mechanical response values.
7. To visualize the applied force and mechanical response using MATLAB plots.

---

## 3. Theory

The DIA-TISSUE mechanical system is represented using a lumped mass-spring-damper model.

The governing equation is:

m*x'' + c*x' + k*x = F(t)

where:

m  = effective mass (kg)

c  = damping coefficient (N*s/m)

k  = stiffness (N/m)

x  = displacement (m)

x' = velocity (m/s)

x'' = acceleration (m/s^2)

F(t) = applied excitation force (N)

The applied excitation is sinusoidal:

F(t) = F0*sin(2*pi*f*t)

where:

F0 = force amplitude (N)

f = excitation frequency (Hz)

---

## 4. Natural Frequency

The theoretical natural frequency of the mechanical system is:

fn = (1/(2*pi))*sqrt(k/m)

For Model A:

m = 0.0200 kg

k = 800 N/m

Therefore:

fn = (1/(2*pi))*sqrt(800/0.0200)

fn = 31.83 Hz

---

## 5. Damping Ratio

The damping ratio is calculated using:

zeta = c/(2*sqrt(k*m))

For Model A:

c = 2.00 N*s/m

k = 800 N/m

m = 0.0200 kg

Therefore:

zeta = 2/(2*sqrt(800*0.0200))

zeta = 0.250

---

## 6. Simulation Parameters

| Parameter | Symbol | Value | Unit |
|---|---|---:|---|
| Effective mass | m | 0.0200 | kg |
| Excitation frequency | f | 30.0 | Hz |
| Force amplitude | F0 | 0.100 | N |
| Model | — | Model A | — |
| Tissue stiffness | k | 800.0 | N/m |
| Damping coefficient | c | 2.00 | N*s/m |
| Natural frequency | fn | 31.83 | Hz |
| Damping ratio | zeta | 0.250 | — |

---

## 7. Model Description

### Model A — Compliant

| Parameter | Value |
|---|---:|
| Mass | 0.0200 kg |
| Stiffness | 800.00 N/m |
| Damping | 2.00 N*s/m |
| Excitation frequency | 30.00 Hz |
| Force amplitude | 0.100 N |
| Natural frequency | 31.83 Hz |
| Damping ratio | 0.250 |

Model A is used as the baseline/compliant mechanical model.

The model represents a controlled mechanical-property condition only and must not be interpreted as a specific clinical or disease stage.

---

## 8. MATLAB Implementation

The experiment uses the following common MATLAB files:

common/simulation_parameters.m

common/tissue_model.m

The experiment-specific MATLAB file is:

01_Baseline_Mechanical_Response/experiment_baseline.m

The tissue model solves:

m*x'' + c*x' + k*x = F(t)

using numerical integration.

---

## 9. Simulation Procedure

1. Load the common simulation parameters.
2. Select Model A parameters.
3. Define the initial displacement and velocity as zero.
4. Generate the sinusoidal excitation force.
5. Solve the mass-spring-damper differential equation.
6. Extract displacement and velocity.
7. Calculate acceleration from the equation of motion.
8. Calculate peak and RMS values.
9. Generate MATLAB graphs.
10. Save the graphs inside the results folder.

---

## 10. MATLAB Output

The MATLAB simulation successfully loaded the following parameters:

Effective mass = 0.0200 kg

Excitation frequency = 30.0 Hz

Force amplitude = 0.100 N

### Model A

Stiffness = 800.0 N/m

Damping coefficient = 2.00 N*s/m

Natural frequency = 31.83 Hz

Damping ratio = 0.250

The experiment then selected Model A as the compliant baseline model:

Mass = 0.0200 kg

Stiffness = 800.00 N/m

Damping = 2.00 N*s/m

Excitation = 30.00 Hz

Force amplitude = 0.100 N

---

## 11. Output Parameter Table

| Quantity | Result | Unit |
|---|---:|---|
| Effective mass | 0.0200 | kg |
| Stiffness | 800.00 | N/m |
| Damping coefficient | 2.00 | N*s/m |
| Excitation frequency | 30.00 | Hz |
| Force amplitude | 0.100 | N |
| Natural frequency | 31.83 | Hz |
| Damping ratio | 0.250 | — |

---

## 12. Graphical Results

The MATLAB-generated graphs are available in the results folder.

### Graph 1 — Applied Force

File:

results/baseline_force.png

This graph shows the sinusoidal excitation force applied to the mechanical model as a function of time.

### Graph 2 — Baseline Displacement

File:

results/baseline_displacement.png

This graph shows the displacement response of Model A under the applied sinusoidal excitation.

### Graph 3 — Baseline Velocity

File:

results/baseline_velocity.png

This graph shows the corresponding velocity response of the mechanical model.

### Graph 4 — Baseline Acceleration

File:

results/baseline_acceleration.png

This graph shows the acceleration response obtained from the mass-spring-damper model.

---

## 13. Results Folder

The experiment stores the generated MATLAB graphs in:

01_Baseline_Mechanical_Response/results/

The available result files are:

| File | Description |
|---|---|
| baseline_force.png | Applied sinusoidal excitation |
| baseline_displacement.png | Model A displacement response |
| baseline_velocity.png | Model A velocity response |
| baseline_acceleration.png | Model A acceleration response |

---

## 14. Observation

The baseline simulation establishes the mechanical response of Model A under a 30 Hz sinusoidal excitation.

The theoretical natural frequency of Model A is 31.83 Hz, while the applied excitation frequency is 30 Hz.

Therefore, the excitation frequency is relatively close to the theoretical natural frequency of the baseline model.

The simulation produces corresponding displacement, velocity, and acceleration responses, which are visualized using the generated MATLAB graphs.

---

## 15. Result

The baseline mass-spring-damper model was successfully implemented and simulated.

For the selected Model A parameters:

Natural frequency = 31.83 Hz

Damping ratio = 0.250

Excitation frequency = 30.00 Hz

Force amplitude = 0.100 N

The simulation successfully generated the applied force, displacement, velocity, and acceleration response plots.

---

## 16. Inference

The experiment establishes the baseline mechanical simulation framework for the DIA-TISSUE project.

The model demonstrates that a sinusoidal mechanical excitation can be converted into measurable simulated displacement, velocity, and acceleration responses.

This baseline model provides the reference condition for the subsequent experiments involving:

- stiffness comparison
- frequency response
- FFT analysis
- sensor simulation
- noise and SNR analysis
- contact-force sensitivity
- load-cell validation
- VCA electrical modeling

The results are useful for engineering-level simulation and feasibility analysis.

---

## 17. Limitations

1. The tissue model is a simplified lumped mass-spring-damper representation.
2. The parameters are simulation assumptions and are not experimentally measured tissue properties.
3. The model does not represent a specific disease stage.
4. The simulation does not provide clinical diagnosis.
5. Real biological tissue is nonlinear and heterogeneous.
6. Real tissue may exhibit frequency-dependent and nonlinear viscoelastic behavior.
7. The actuator and sensor characteristics are not fully represented in this baseline experiment.
8. Experimental validation with measured hardware data is required for future development.

---

## 18. Conclusion

A baseline mechanical simulation of the DIA-TISSUE system was successfully developed using a lumped mass-spring-damper model.

The Model A condition was simulated using an effective mass of 0.0200 kg, stiffness of 800 N/m, damping coefficient of 2.00 N*s/m, excitation frequency of 30 Hz, and force amplitude of 0.100 N.

The theoretical natural frequency was calculated as 31.83 Hz with a damping ratio of 0.250.

The simulation successfully produced force, displacement, velocity, and acceleration responses, establishing the baseline for the remaining DIA-TISSUE MATLAB experiments.

---

## 19. Repository Structure

01_Baseline_Mechanical_Response/

    experiment_baseline.m

    results/
        baseline_force.png
        baseline_displacement.png
        baseline_velocity.png
        baseline_acceleration.png

Common project files:

common/

    simulation_parameters.m

    tissue_model.m

---

## 20. Simulation Disclaimer

This experiment is an engineering simulation.

All mechanical, excitation, stiffness, damping, sensor, and actuator parameters used in the simulation are assumed values unless explicitly stated otherwise.

The results must not be interpreted as clinical measurements, clinical thresholds, or disease-stage classifications.