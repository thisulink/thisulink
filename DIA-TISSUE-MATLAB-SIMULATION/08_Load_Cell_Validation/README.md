# Experiment 8 - Load Cell Validation

## 1. Aim

To validate simulated contact-force measurements using a load-cell model with measurement noise and predefined research force limits.

The experiment evaluates whether low, target, and high contact-force conditions are classified as invalid contact, valid scan, or excessive contact.

Note: This experiment is an engineering simulation. The force limits used here are research simulation parameters and are NOT clinical limits.

## 2. Objective

The objectives of this experiment are:

1. To define lower and upper contact-force limits.
2. To simulate load-cell measurement noise.
3. To compare true contact force with measured force.
4. To classify the contact condition.
5. To verify whether the target contact condition falls within the defined measurement range.
6. To study the effect of load-cell noise on contact-force validation.

## 3. Theory

A load cell measures the mechanical contact force applied to the DIA-TISSUE system.

The simulated measured force is represented as:

F_measured = F_true + noise

where:

F_measured = measured load-cell force (N)

F_true = actual contact force (N)

noise = simulated load-cell measurement noise (N)

The measurement is then compared with predefined lower and upper force limits.

The validation logic is:

If F_measured < Lower Limit:

INVALID CONTACT

If Lower Limit <= F_measured <= Upper Limit:

VALID SCAN

If F_measured > Upper Limit:

EXCESSIVE CONTACT

## 4. Simulation Parameters

| Parameter | Value | Unit |
|---|---:|---|
| Effective mass | 0.0200 | kg |
| Excitation frequency | 30.0 | Hz |
| Force amplitude | 0.100 | N |
| Lower force limit | 1.50 | N |
| Upper force limit | 2.50 | N |
| Load-cell noise standard deviation | 0.030 | N |

## 5. Test Conditions

Three contact conditions were evaluated:

| Condition | True Force (N) |
|---|---:|
| Low Contact | 1.00 |
| Target Contact | 2.00 |
| High Contact | 3.00 |

## 6. Validation Limits

The simulation uses the following research limits:

Lower force limit = 1.50 N

Upper force limit = 2.50 N

Therefore:

1. Measurements below 1.50 N are classified as INVALID CONTACT.
2. Measurements from 1.50 N to 2.50 N are classified as VALID SCAN.
3. Measurements above 2.50 N are classified as EXCESSIVE CONTACT.

## 7. Load Cell Noise Model

The simulated load-cell measurement is:

F_measured = F_true + N(0,sigma)

where:

sigma = load-cell noise standard deviation

For this experiment:

sigma = 0.030 N

Random measurement noise is therefore added to each true contact-force value.

## 8. MATLAB Files

The experiment uses:

08_Load_Cell_Validation/experiment_load_cell.m

Common files:

common/simulation_parameters.m

The common files are not modified by this experiment.

## 9. Simulation Procedure

1. Load the common DIA-TISSUE simulation parameters.
2. Define the lower force limit.
3. Define the upper force limit.
4. Define the load-cell noise standard deviation.
5. Define low, target, and high contact conditions.
6. Generate simulated measured-force values.
7. Compare each measured value with the validation limits.
8. Assign the corresponding contact status.
9. Display the validation results.
10. Generate the load-cell validation graphs.
11. Save the graphs in the results folder.

## 10. Actual MATLAB Output

The MATLAB simulation produced the following parameters:

Lower force limit = 1.50 N

Upper force limit = 2.50 N

Load-cell noise = 0.030 N std

The measured results were:

| Condition | True Force (N) | Mean Measured (N) | Status |
|---|---:|---:|---|
| Low Contact | 1.00 | 0.9805 | INVALID CONTACT |
| Target Contact | 2.00 | 2.0354 | VALID SCAN |
| High Contact | 3.00 | 2.9772 | EXCESSIVE CONTACT |

## 11. Detailed Results

### Low Contact

True force:

1.00 N

Measured force:

0.9805 N

Status:

INVALID CONTACT

The measured force is below the lower force limit of 1.50 N.

### Target Contact

True force:

2.00 N

Measured force:

2.0354 N

Status:

VALID SCAN

The measured force lies between the lower limit of 1.50 N and upper limit of 2.50 N.

### High Contact

True force:

3.00 N

Measured force:

2.9772 N

Status:

EXCESSIVE CONTACT

The measured force is above the upper force limit of 2.50 N.

## 12. Results Table

| Condition | True Force (N) | Measured Force (N) | Validation Status |
|---|---:|---:|---|
| Low Contact | 1.00 | 0.9805 | INVALID CONTACT |
| Target Contact | 2.00 | 2.0354 | VALID SCAN |
| High Contact | 3.00 | 2.9772 | EXCESSIVE CONTACT |

## 13. Graphical Results

The MATLAB-generated graphs are available in the results folder.

### Graph 1 - True vs Measured Force

File:

results/load_cell_true_vs_measured.png

This graph compares the true contact force with the simulated load-cell measurement for the three contact conditions.

### Graph 2 - Load Cell Validation Limits

File:

results/load_cell_validation_limits.png

This graph shows the measured contact-force values together with the lower and upper validation limits.

## 14. Results Folder

The generated graph files are stored in:

08_Load_Cell_Validation/results/

| File | Description |
|---|---|
| load_cell_true_vs_measured.png | True versus measured contact force |
| load_cell_validation_limits.png | Measured force with validation limits |

## 15. Observation

The simulated load-cell measurements are close to their corresponding true-force values despite the addition of measurement noise.

The low-contact condition produced a measured force of 0.9805 N, which is below the lower limit of 1.50 N and was classified as INVALID CONTACT.

The target-contact condition produced a measured force of 2.0354 N, which lies within the valid range of 1.50 N to 2.50 N and was classified as VALID SCAN.

The high-contact condition produced a measured force of 2.9772 N, which is above the upper limit of 2.50 N and was classified as EXCESSIVE CONTACT.

## 16. Result

The load-cell validation experiment was successfully performed.

The three simulated contact conditions were correctly classified:

Low Contact:

1.00 N true force

0.9805 N measured force

INVALID CONTACT

Target Contact:

2.00 N true force

2.0354 N measured force

VALID SCAN

High Contact:

3.00 N true force

2.9772 N measured force

EXCESSIVE CONTACT

The simulation demonstrates that contact-force limits can be used to validate whether a measurement is suitable for further scanning under the defined research conditions.

## 17. Inference

The experiment demonstrates the importance of contact-force control in the DIA-TISSUE measurement process.

A measurement taken with insufficient contact force may be rejected as INVALID CONTACT.

A measurement within the predefined range may be accepted as a VALID SCAN.

A measurement with excessive contact force may be rejected as EXCESSIVE CONTACT.

Therefore, load-cell feedback can be used as an engineering-level measurement-quality control mechanism before accepting a tissue-response measurement.

These limits are simulation assumptions and do not represent clinical thresholds.

## 18. Limitations

1. The load cell is simulated rather than physically tested.
2. The force limits are assumed research parameters.
3. The load-cell noise is modeled using a simplified random-noise model.
4. Real load cells may exhibit hysteresis, drift, nonlinearity, temperature dependence, and calibration errors.
5. Mechanical mounting effects are not included.
6. The experiment does not include real sensor calibration data.
7. The validation limits have not been experimentally established.
8. The limits must not be interpreted as clinical safety or diagnostic limits.

## 19. Conclusion

The DIA-TISSUE load-cell validation experiment was successfully simulated using lower and upper contact-force limits of 1.50 N and 2.50 N.

The target contact condition produced a measured force of 2.0354 N and was correctly classified as VALID SCAN.

The low-contact condition was classified as INVALID CONTACT, while the high-contact condition was classified as EXCESSIVE CONTACT.

The experiment demonstrates an engineering approach for using contact-force feedback to control measurement conditions before accepting a DIA-TISSUE scan.

## 20. Repository Structure

08_Load_Cell_Validation/

    experiment_load_cell.m

    README.md

    results/

        load_cell_true_vs_measured.png

        load_cell_validation_limits.png

Common project files:

common/

    simulation_parameters.m

    tissue_model.m

## 21. Simulation Disclaimer

This experiment is an engineering simulation.

The force limits, load-cell noise, mechanical parameters, and validation conditions are simulation assumptions unless experimentally measured values are explicitly stated.

The lower and upper force limits used in this experiment are NOT clinical limits.

The results must not be interpreted as clinical measurements, diagnostic thresholds, or disease-stage classifications.