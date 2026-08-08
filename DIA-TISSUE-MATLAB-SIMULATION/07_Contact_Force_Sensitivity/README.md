# Experiment 7 - Contact Force Sensitivity

## 1. Aim

To investigate the effect of contact force on the effective stiffness, natural frequency, and acceleration response of the DIA-TISSUE mechanical model.

The experiment evaluates three contact conditions:

- Low Contact
- Target Contact
- High Contact

Note: This experiment is an engineering simulation. The parameters and results are simulation assumptions and are NOT clinical values.

## 2. Objective

The objectives of this experiment are:

1. To define a baseline tissue stiffness.
2. To define a target contact force.
3. To model the relationship between contact force and effective stiffness.
4. To calculate the natural frequency for different contact forces.
5. To calculate the corresponding acceleration response.
6. To observe the influence of contact force on the mechanical response.

## 3. Theory

Contact force can influence the effective mechanical stiffness of the coupled probe-tissue system.

In this simulation, effective stiffness is modeled using a linear contact-sensitivity relationship:

k_eff = k_base + alpha*(F_contact - F_target)

where:

k_eff = effective stiffness (N/m)

k_base = baseline tissue stiffness (N/m)

alpha = contact sensitivity coefficient (N/m)/N

F_contact = applied contact force (N)

F_target = target contact force (N)

The natural frequency is calculated using:

fn = (1/(2*pi))*sqrt(k_eff/m)

where:

m = effective mass (kg)

The steady-state acceleration response is calculated from the harmonic mechanical response.

For the excitation frequency:

w = 2*pi*f

The mechanical dynamic stiffness is:

D(jw) = (k_eff - m*w^2) + j*c*w

The displacement amplitude is:

X = F0 / D(jw)

The acceleration amplitude is:

A = w^2*|X|

## 4. Simulation Parameters

| Parameter | Symbol | Value | Unit |
|---|---|---:|---|
| Effective mass | m | 0.0200 | kg |
| Excitation frequency | f | 30.0 | Hz |
| Force amplitude | F0 | 0.100 | N |
| Baseline tissue stiffness | k_base | 800.0 | N/m |
| Target contact force | F_target | 2.0 | N |
| Contact sensitivity | alpha | 150.0 | (N/m)/N |
| Damping coefficient | c | 2.00 | N*s/m |

## 5. Contact Conditions

Three contact-force conditions were evaluated:

| Condition | Contact Force (N) |
|---|---:|
| Low Contact | 1.00 |
| Target Contact | 2.00 |
| High Contact | 3.00 |

## 6. Effective Stiffness Model

The effective stiffness was calculated using:

k_eff = k_base + alpha*(F_contact - F_target)

### Low Contact

F_contact = 1.00 N

k_eff = 800 + 150*(1 - 2)

k_eff = 650 N/m

### Target Contact

F_contact = 2.00 N

k_eff = 800 + 150*(2 - 2)

k_eff = 800 N/m

### High Contact

F_contact = 3.00 N

k_eff = 800 + 150*(3 - 2)

k_eff = 950 N/m

## 7. MATLAB Files

The experiment uses:

07_Contact_Force_Sensitivity/experiment_contact_force.m

Common files:

common/simulation_parameters.m

common/tissue_model.m

The common files are not modified by this experiment.

## 8. Simulation Procedure

1. Load the common DIA-TISSUE simulation parameters.
2. Define the baseline tissue stiffness.
3. Define the target contact force.
4. Define the contact sensitivity coefficient.
5. Define low, target, and high contact conditions.
6. Calculate the effective stiffness for each condition.
7. Calculate the theoretical natural frequency.
8. Calculate the steady-state acceleration response.
9. Display the calculated values.
10. Generate the contact-force sensitivity graphs.
11. Save the graphs in the results folder.

## 9. Actual MATLAB Output

The MATLAB simulation produced the following parameters:

Baseline tissue stiffness = 800.0 N/m

Target contact force = 2.0 N

Contact sensitivity alpha = 150.0 (N/m)/N

The simulation results were:

| Condition | Force (N) | Effective Stiffness (N/m) | Natural Frequency (Hz) | Acceleration (m/s^2) |
|---|---:|---:|---:|---:|
| Low Contact | 1.00 | 650.00 | 28.69 | 9.3053 |
| Target Contact | 2.00 | 800.00 | 31.83 | 9.1705 |
| High Contact | 3.00 | 950.00 | 34.69 | 7.9562 |

## 10. Detailed Results

### Low Contact

Contact force = 1.00 N

Effective stiffness = 650.00 N/m

Natural frequency = 28.69 Hz

Acceleration = 9.3053 m/s^2

Status:

Low contact condition.

### Target Contact

Contact force = 2.00 N

Effective stiffness = 800.00 N/m

Natural frequency = 31.83 Hz

Acceleration = 9.1705 m/s^2

Status:

Target contact condition.

### High Contact

Contact force = 3.00 N

Effective stiffness = 950.00 N/m

Natural frequency = 34.69 Hz

Acceleration = 7.9562 m/s^2

Status:

High contact condition.

## 11. Graphical Results

The MATLAB-generated graphs are available in the results folder.

### Graph 1 - Contact Force vs Effective Stiffness

File:

results/contact_force_vs_stiffness.png

This graph shows how the assumed effective stiffness changes as the contact force changes.

### Graph 2 - Contact Force vs Natural Frequency

File:

results/contact_force_vs_natural_frequency.png

This graph shows the change in theoretical natural frequency with contact force.

### Graph 3 - Contact Force vs Acceleration

File:

results/contact_force_vs_acceleration.png

This graph shows the simulated acceleration response for the three contact-force conditions.

## 12. Results Folder

The generated graph files are stored in:

07_Contact_Force_Sensitivity/results/

| File | Description |
|---|---|
| contact_force_vs_stiffness.png | Contact force versus effective stiffness |
| contact_force_vs_natural_frequency.png | Contact force versus natural frequency |
| contact_force_vs_acceleration.png | Contact force versus acceleration |

## 13. Observation

As contact force increases from 1.00 N to 3.00 N, the effective stiffness increases:

650.00 N/m → 800.00 N/m → 950.00 N/m

The corresponding natural frequency also increases:

28.69 Hz → 31.83 Hz → 34.69 Hz

However, at the fixed excitation frequency of 30 Hz, the simulated acceleration response decreases:

9.3053 m/s^2 → 9.1705 m/s^2 → 7.9562 m/s^2

Therefore, the simulated mechanical response depends on the contact force applied to the system.

## 14. Result

The contact-force sensitivity experiment was successfully performed.

The simulation demonstrated that increasing contact force changes the assumed effective stiffness and consequently changes the natural frequency and acceleration response.

The effective stiffness increased from 650.00 N/m at 1.00 N contact force to 950.00 N/m at 3.00 N contact force.

The natural frequency increased from 28.69 Hz to 34.69 Hz.

The acceleration response decreased from 9.3053 m/s^2 to 7.9562 m/s^2 under the selected 30 Hz excitation condition.

## 15. Inference

The simulation indicates that contact force is an important mechanical variable in the DIA-TISSUE measurement system.

Changes in contact force can alter the effective mechanical stiffness and shift the natural frequency of the coupled system.

Therefore, controlling or measuring contact force is important when comparing mechanical response measurements.

This experiment provides an engineering basis for including contact-force monitoring in the overall DIA-TISSUE system.

The result does not establish clinical tissue classification or diagnostic capability.

## 16. Limitations

1. The contact-force relationship is a simplified linear model.
2. The contact sensitivity coefficient is an assumed simulation parameter.
3. The baseline stiffness is an assumed value.
4. The model does not represent nonlinear tissue-contact behavior.
5. Real tissue contact mechanics may depend on probe geometry, tissue properties, deformation, and contact area.
6. The simulation does not include experimental load-cell measurements.
7. The excitation and mechanical parameters are controlled simulation values.
8. Experimental validation is required before applying this relationship to physical measurements.

## 17. Conclusion

The DIA-TISSUE contact-force sensitivity experiment was successfully simulated for low, target, and high contact conditions.

The contact force was varied from 1.00 N to 3.00 N.

The corresponding effective stiffness changed from 650.00 N/m to 950.00 N/m, while the natural frequency changed from 28.69 Hz to 34.69 Hz.

At the selected 30 Hz excitation frequency, the acceleration response changed from 9.3053 m/s^2 for low contact to 7.9562 m/s^2 for high contact.

The experiment demonstrates that contact force can significantly influence the simulated mechanical response and should therefore be considered during controlled mechanical measurements.

## 18. Repository Structure

07_Contact_Force_Sensitivity/

    experiment_contact_force.m

    README.md

    results/

        contact_force_vs_stiffness.png

        contact_force_vs_natural_frequency.png

        contact_force_vs_acceleration.png

Common project files:

common/

    simulation_parameters.m

    tissue_model.m

## 19. Simulation Disclaimer

This experiment is an engineering simulation.

The contact-force values, stiffness values, contact sensitivity coefficient, damping, mass, excitation, and force values are simulation assumptions unless experimentally measured values are explicitly stated.

The results must not be interpreted as clinical measurements, diagnostic thresholds, or disease-stage classifications.