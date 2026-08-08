# Experiment 9 - VCA Electrical Test

## 1. Aim

To simulate and evaluate the electrical response of a Voice Coil Actuator (VCA) under a sinusoidal voltage excitation and determine the corresponding current and force response.

Note: This experiment uses placeholder actuator parameters and is an engineering simulation. The parameters and results are NOT clinical values.

## 2. Objective

The objectives of this experiment are:

1. To define the electrical parameters of a VCA.
2. To calculate the electrical impedance of the actuator.
3. To determine the peak and RMS current.
4. To calculate the corresponding actuator force.
5. To compare the simulated current and force with theoretical values.
6. To evaluate the electrical response of the actuator at the selected excitation frequency.

## 3. Theory

A Voice Coil Actuator can be represented using an electrical resistance and inductance.

The electrical impedance is:

Z = R + j*w*L

where:

R = coil resistance (Ohm)

L = coil inductance (H)

w = angular frequency (rad/s)

The angular frequency is:

w = 2*pi*f

The magnitude of electrical impedance is:

|Z| = sqrt(R^2 + (w*L)^2)

The peak current is:

I_peak = V_peak / |Z|

The RMS current is:

I_RMS = I_peak / sqrt(2)

The actuator force is related to current through the force constant:

F = Kf*I

where:

Kf = force constant (N/A)

Therefore:

F_peak = Kf*I_peak

F_RMS = Kf*I_RMS

## 4. Simulation Parameters

| Parameter | Symbol | Value | Unit |
|---|---|---:|---|
| Effective mass | m | 0.0200 | kg |
| Excitation frequency | f | 30.00 | Hz |
| Force amplitude | F0 | 0.100 | N |
| Resistance | R | 8.0000 | Ohm |
| Inductance | L | 0.005000 | H |
| Force constant | Kf | 1.0000 | N/A |
| Back-EMF constant | Ke | 1.0000 | V/(m/s) |
| Voltage peak | V_peak | 1.0000 | V |

## 5. VCA Parameters

The VCA parameters used in this experiment are placeholder values.

| Parameter | Value | Unit |
|---|---:|---|
| Resistance | 8.0000 | Ohm |
| Inductance | 0.005000 | H |
| Force constant | 1.0000 | N/A |
| Back-EMF constant | 1.0000 | V/(m/s) |

Important:

These parameters must be replaced after the exact VCA actuator is selected and its datasheet parameters are available.

## 6. Command Parameters

| Parameter | Value | Unit |
|---|---:|---|
| Command frequency | 30.00 | Hz |
| Voltage peak | 1.0000 | V |

The actuator is simulated using a 1.0000 V peak sinusoidal voltage at 30.00 Hz.

## 7. Electrical Impedance

The impedance magnitude is calculated using:

|Z| = sqrt(R^2 + (2*pi*f*L)^2)

For the selected parameters:

R = 8.0000 Ohm

L = 0.005000 H

f = 30.00 Hz

The theoretical electrical impedance magnitude obtained is:

|Z| = 8.055325 Ohm

## 8. MATLAB Files

The experiment uses:

09_VCA_Electrical_Test/experiment_vca.m

Common file:

common/simulation_parameters.m

The common files are not modified by this experiment.

## 9. Simulation Procedure

1. Load the common DIA-TISSUE simulation parameters.
2. Define the VCA resistance.
3. Define the VCA inductance.
4. Define the force constant.
5. Define the back-EMF constant.
6. Define the command frequency.
7. Define the voltage amplitude.
8. Calculate the electrical impedance.
9. Calculate the peak current.
10. Calculate the RMS current.
11. Calculate the peak actuator force.
12. Calculate the RMS actuator force.
13. Compare the simulated values with the theoretical values.
14. Generate the electrical response graphs.
15. Save the graphs in the results folder.

## 10. Actual MATLAB Output

The MATLAB simulation produced the following output:

### Placeholder Parameters

Resistance R = 8.0000 Ohm

Inductance L = 0.005000 H

Force constant Kf = 1.0000 N/A

Back-EMF Ke = 1.0000 V/(m/s)

### Command

Frequency = 30.00 Hz

Voltage peak = 1.0000 V

### Simulated Response

Peak current = 0.124141 A

RMS current = 0.087781 A

Peak force = 0.124141 N

RMS force = 0.087781 N

### Theoretical Check

|Electrical Z| = 8.055325 Ohm

Expected I peak = 0.124141 A

Expected F peak = 0.124141 N

Original ideal F0 = 0.100000 N

## 11. Results Table

| Quantity | Simulated Result | Unit |
|---|---:|---|
| Electrical impedance magnitude | 8.055325 | Ohm |
| Peak current | 0.124141 | A |
| RMS current | 0.087781 | A |
| Peak force | 0.124141 | N |
| RMS force | 0.087781 | N |
| Expected peak current | 0.124141 | A |
| Expected peak force | 0.124141 | N |
| Original ideal force | 0.100000 | N |

## 12. Graphical Results

The MATLAB-generated graphs are available in the results folder.

### Graph 1 - VCA Electrical Impedance

File:

results/vca_impedance.png

This graph shows the magnitude of the VCA electrical impedance as a function of frequency.

### Graph 2 - VCA Current Response

File:

results/vca_current_response.png

This graph shows the peak current response of the VCA for the selected voltage command over the simulated frequency range.

### Graph 3 - VCA Force Response

File:

results/vca_force_response.png

This graph shows the simulated peak actuator force as a function of excitation frequency.

## 13. Results Folder

The generated graph files are stored in:

09_VCA_Electrical_Test/results/

| File | Description |
|---|---|
| vca_impedance.png | VCA electrical impedance response |
| vca_current_response.png | VCA current response |
| vca_force_response.png | VCA force response |

## 14. Observation

At the selected command frequency of 30.00 Hz and voltage peak of 1.0000 V, the calculated electrical impedance magnitude is:

8.055325 Ohm

The corresponding peak current is:

0.124141 A

The RMS current is:

0.087781 A

Using the force constant of 1.0000 N/A, the corresponding peak actuator force is:

0.124141 N

The RMS actuator force is:

0.087781 N

The calculated peak current and peak force agree with the theoretical values shown in the MATLAB output.

## 15. Result

The VCA electrical simulation was successfully performed.

At 30.00 Hz and 1.0000 V peak excitation:

Electrical impedance = 8.055325 Ohm

Peak current = 0.124141 A

RMS current = 0.087781 A

Peak force = 0.124141 N

RMS force = 0.087781 N

The theoretical current and force calculations agree with the simulated response.

## 16. Inference

The experiment demonstrates the relationship between the electrical characteristics of a VCA and its resulting current and force response.

The actuator impedance determines the current drawn for a given voltage command.

The actuator force is then determined from the current through the force constant Kf.

Therefore, the electrical actuator model provides a link between the commanded voltage and the mechanical excitation force required for the DIA-TISSUE mechanical system.

This experiment establishes an engineering-level actuator model for future integration with the mechanical simulation.

## 17. Limitations

1. The VCA parameters are placeholder values.
2. The exact physical VCA has not yet been selected.
3. The force constant is assumed.
4. The back-EMF constant is assumed.
5. The simulation does not include actuator saturation.
6. Thermal effects are not modeled.
7. Coil resistance variation with temperature is not modeled.
8. Mechanical friction is not modeled.
9. The actuator's actual mechanical resonance is not included.
10. The actuator model must be updated using the selected VCA datasheet parameters.
11. Experimental hardware validation is required.

## 18. Important Engineering Note

The MATLAB output shows:

Original ideal F0 = 0.100000 N

while the VCA model produces:

Peak force = 0.124141 N

Therefore, the selected placeholder VCA parameters and 1.0000 V command do not exactly reproduce the original 0.100 N ideal excitation force.

The VCA command voltage should therefore be adjusted after the exact actuator is selected if the required mechanical excitation amplitude is 0.100 N.

For an idealized force constant of Kf = 1.0000 N/A, the required current for 0.100 N peak force would be:

I_required = F0/Kf

I_required = 0.100 A

The corresponding voltage command should then be determined from the actual actuator electrical impedance.

## 19. Conclusion

The DIA-TISSUE VCA electrical simulation was successfully performed using the specified placeholder actuator parameters.

At a 30 Hz excitation frequency and 1 V peak command, the electrical impedance magnitude was 8.055325 Ohm.

The resulting peak current was 0.124141 A and the corresponding peak actuator force was 0.124141 N.

The theoretical and simulated current and force values were consistent.

The experiment establishes the electrical-to-force relationship required for connecting the actuator subsystem with the DIA-TISSUE mechanical simulation.

The VCA parameters must be replaced with experimentally verified or datasheet values after the exact physical actuator is selected.

## 20. Repository Structure

09_VCA_Electrical_Test/

    experiment_vca.m

    README.md

    results/

        vca_impedance.png

        vca_current_response.png

        vca_force_response.png

Common project files:

common/

    simulation_parameters.m

    tissue_model.m

## 21. Simulation Disclaimer

This experiment is an engineering simulation.

The VCA resistance, inductance, force constant, back-EMF constant, voltage, and other actuator parameters are placeholder or simulation values unless experimentally verified.

The results must not be interpreted as clinical measurements, diagnostic thresholds, or disease-stage classifications.