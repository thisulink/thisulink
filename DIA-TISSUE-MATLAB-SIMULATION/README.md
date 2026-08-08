# DIA-TISSUE MATLAB Simulation

## Overview

DIA-TISSUE is an engineering simulation framework developed in MATLAB to study the mechanical, sensing, signal-processing, contact-force, and actuator characteristics of a tissue-interaction measurement system.

The project uses a controlled mass-spring-damper representation together with simulated sensor, load-cell, signal-processing, and VCA actuator models.

Note: This repository contains engineering simulations and research assumptions. The parameters and results are NOT clinical values, clinical limits, diagnostic thresholds, or disease-stage classifications.

---

## Project Objectives

The main objectives of the simulation framework are:

1. Develop a baseline mechanical tissue-response model.
2. Study the effect of mechanical stiffness.
3. Analyze frequency-dependent response.
4. Extract frequency-domain information using FFT.
5. Simulate accelerometer measurements.
6. Study the effect of sensor noise and SNR.
7. Analyze contact-force sensitivity.
8. Validate simulated load-cell measurements.
9. Model the electrical response of a Voice Coil Actuator (VCA).
10. Establish an engineering simulation pipeline for future hardware validation.

---

## Overall Simulation Pipeline

The DIA-TISSUE simulation is organized as:

Mechanical Model
        |
        v
Baseline Response
        |
        v
Stiffness Comparison
        |
        v
Frequency Sweep
        |
        v
FFT Analysis
        |
        v
Sensor Simulation
        |
        v
Noise / SNR Analysis
        |
        v
Contact Force Sensitivity
        |
        v
Load Cell Validation
        |
        v
VCA Electrical Test
        |
        v
Future Hardware Validation

---

## Common Mechanical Model

The core mechanical system is represented using a lumped mass-spring-damper model.

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

The excitation force is represented as:

F(t) = F0*sin(2*pi*f*t)

---

## Common Simulation Parameters

The current common simulation parameters are:

| Parameter | Value | Unit |
|---|---:|---|
| Effective mass | 0.0200 | kg |
| Excitation frequency | 30.0 | Hz |
| Force amplitude | 0.100 | N |

---

## Mechanical Models

Three mechanical models are defined in the common simulation parameters.

| Model | Description | Stiffness (N/m) | Damping (N*s/m) | Natural Frequency (Hz) | Damping Ratio |
|---|---|---:|---:|---:|---:|
| Model A | Compliant | 800.0 | 2.00 | 31.83 | 0.250 |
| Model B | Moderately Increased Stiffness | 1400.0 | 2.00 | 42.11 | 0.189 |
| Model C | Substantially Increased Stiffness | 2200.0 | 2.00 | 52.79 | 0.151 |

The theoretical natural frequency is:

fn = (1/(2*pi))*sqrt(k/m)

The damping ratio is:

zeta = c/(2*sqrt(k*m))

---

# Experiments

## Experiment 1 - Baseline Mechanical Response

Folder:

01_Baseline_Mechanical_Response/

### Purpose

To establish the baseline mechanical response of Model A using the mass-spring-damper representation.

### Model

Model A - Compliant

### Parameters

Mass = 0.0200 kg

Stiffness = 800.0 N/m

Damping = 2.00 N*s/m

Excitation = 30.00 Hz

Force amplitude = 0.100 N

Natural frequency = 31.83 Hz

Damping ratio = 0.250

### Outputs

The experiment generates:

- Applied force
- Displacement
- Velocity
- Acceleration

### Result Files

results/baseline_force.png

results/baseline_displacement.png

results/baseline_velocity.png

results/baseline_acceleration.png

---

## Experiment 2 - Stiffness Comparison

Folder:

02_Stiffness_Comparison/

### Purpose

To investigate the effect of increasing mechanical stiffness on the simulated acceleration response.

### Models

Model A = 800.0 N/m

Model B = 1400.0 N/m

Model C = 2200.0 N/m

### Results

| Model | Stiffness (N/m) | Natural Frequency (Hz) | Peak Acceleration (m/s^2) | RMS Acceleration (m/s^2) |
|---|---:|---:|---:|---:|
| Model A | 800.0 | 31.83 | 9.1649 | 6.3889 |
| Model B | 1400.0 | 42.11 | 5.5696 | 3.2088 |
| Model C | 2200.0 | 52.79 | 3.6542 | 1.6570 |

### Observation

Increasing stiffness increases the theoretical natural frequency.

Under the selected 30 Hz excitation condition, the simulated acceleration response decreases from Model A to Model C.

---

## Experiment 3 - Frequency Sweep

Folder:

03_Frequency_Sweep/

### Purpose

To study the acceleration response over a frequency range of 10 Hz to 500 Hz.

### Sweep Parameters

Frequency range = 10.0 - 500.0 Hz

Frequency step = 1.0 Hz

Number of points = 491

### Results

| Model | Stiffness (N/m) | Theoretical Natural Frequency (Hz) | Peak Acceleration Frequency (Hz) | Peak Acceleration (m/s^2) |
|---|---:|---:|---:|---:|
| Model A | 800.0 | 31.83 | 34.00 | 10.3279 |
| Model B | 1400.0 | 42.11 | 44.00 | 13.4636 |
| Model C | 2200.0 | 52.79 | 54.00 | 16.7748 |

### Observation

The peak acceleration frequency shifts toward higher frequencies as stiffness increases.

Peak response frequencies:

Model A = 34 Hz

Model B = 44 Hz

Model C = 54 Hz

---

## Experiment 4 - FFT Analysis

Folder:

04_FFT_Analysis/

### Purpose

To extract the dominant frequency component from the simulated acceleration signal using FFT.

### Parameters

Model = A - Compliant

Excitation frequency = 30.00 Hz

Sampling frequency = 4000.00 Hz

### Results

| Quantity | Result | Unit |
|---|---:|---|
| Expected excitation frequency | 30.00 | Hz |
| Dominant FFT frequency | 30.00 | Hz |
| FFT peak magnitude | 9.1705 | m/s^2 |
| Frequency resolution | 0.5000 | Hz |

### Observation

The dominant FFT frequency exactly matches the known 30 Hz excitation frequency.

This confirms that the implemented FFT processing can recover the dominant frequency from the simulated acceleration signal.

---

## Experiment 5 - Sensor Simulation

Folder:

05_Sensor_Simulation/

### Purpose

To simulate an ADXL355-like accelerometer measurement including sensor range, resolution, bandwidth, noise density, bias, and quantization.

### Sensor Configuration

| Parameter | Value |
|---|---:|
| Range | +/- 2.0 g |
| Resolution | 20 bits |
| Bandwidth | 150.0 Hz |
| Noise density | 0.000250 m/s^2/sqrt(Hz) |
| Bias | 0.010000 m/s^2 |

### Results

| Parameter | Result | Unit |
|---|---:|---|
| True signal RMS | 6.388942 | m/s^2 |
| Model noise RMS | 0.003062 | m/s^2 |
| Total error RMS | 0.010504 | m/s^2 |
| Estimated SNR | 55.68 | dB |
| Quantization step | 0.000037409 | m/s^2 |

### Observation

The sensor model introduces noise, bias, and quantization into the simulated acceleration measurement.

The resulting estimated SNR is 55.68 dB under the selected simulation conditions.

---

## Experiment 6 - Noise / SNR Analysis

Folder:

06_Noise_SNR_Analysis/

### Purpose

To investigate how increasing sensor noise density affects measurement error, SNR, and detected frequency.

### True Acceleration RMS

6.388942 m/s^2

### Results

| Noise Density (m/s^2/sqrt(Hz)) | Error RMS (m/s^2) | SNR (dB) | Detected Frequency (Hz) |
|---:|---:|---:|---:|
| 0.000250 | 0.010501 | 55.68 | 30.00 |
| 0.001000 | 0.015659 | 52.21 | 30.00 |
| 0.005000 | 0.062666 | 40.17 | 30.00 |
| 0.010000 | 0.122869 | 34.33 | 30.00 |
| 0.050000 | 0.609096 | 20.41 | 30.00 |
| 0.100000 | 1.227085 | 14.33 | 30.00 |

### Observation

As noise density increases:

- Error RMS increases.
- SNR decreases.
- The 30 Hz dominant frequency remains detectable under the tested simulation conditions.

---

## Experiment 7 - Contact Force Sensitivity

Folder:

07_Contact_Force_Sensitivity/

### Purpose

To study the effect of contact force on effective stiffness, natural frequency, and acceleration response.

### Contact Model

The effective stiffness is calculated using:

k_eff = k_base + alpha*(F_contact - F_target)

Simulation parameters:

Baseline stiffness = 800.0 N/m

Target contact force = 2.0 N

Contact sensitivity = 150.0 (N/m)/N

### Results

| Condition | Force (N) | Effective Stiffness (N/m) | Natural Frequency (Hz) | Acceleration (m/s^2) |
|---|---:|---:|---:|---:|
| Low Contact | 1.00 | 650.00 | 28.69 | 9.3053 |
| Target Contact | 2.00 | 800.00 | 31.83 | 9.1705 |
| High Contact | 3.00 | 950.00 | 34.69 | 7.9562 |

### Observation

Increasing contact force increases the assumed effective stiffness and shifts the natural frequency upward.

At the selected 30 Hz excitation, the acceleration response decreases across the tested contact conditions.

---

## Experiment 8 - Load Cell Validation

Folder:

08_Load_Cell_Validation/

### Purpose

To validate simulated contact-force measurements using a load-cell model with measurement noise and predefined research force limits.

### Validation Limits

Lower force limit = 1.50 N

Upper force limit = 2.50 N

Load-cell noise = 0.030 N standard deviation

### Results

| Condition | True Force (N) | Mean Measured (N) | Status |
|---|---:|---:|---|
| Low Contact | 1.00 | 0.9805 | INVALID CONTACT |
| Target Contact | 2.00 | 2.0354 | VALID SCAN |
| High Contact | 3.00 | 2.9772 | EXCESSIVE CONTACT |

### Observation

The target contact condition falls within the defined research range and is classified as VALID SCAN.

The low and high contact conditions are rejected.

This provides an engineering-level contact-quality control mechanism.

---

## Experiment 9 - VCA Electrical Test

Folder:

09_VCA_Electrical_Test/

### Purpose

To simulate the electrical response of a Voice Coil Actuator and calculate its current and force response.

### Placeholder VCA Parameters

| Parameter | Value | Unit |
|---|---:|---|
| Resistance | 8.0000 | Ohm |
| Inductance | 0.005000 | H |
| Force constant | 1.0000 | N/A |
| Back-EMF constant | 1.0000 | V/(m/s) |
| Command frequency | 30.00 | Hz |
| Voltage peak | 1.0000 | V |

### Results

| Quantity | Result | Unit |
|---|---:|---|
| Electrical impedance magnitude | 8.055325 | Ohm |
| Peak current | 0.124141 | A |
| RMS current | 0.087781 | A |
| Peak force | 0.124141 | N |
| RMS force | 0.087781 | N |
| Expected peak current | 0.124141 | A |
| Expected peak force | 0.124141 | N |
| Original ideal force | 0.100000 | N |

### Important Observation

The VCA model produces a peak force of 0.124141 N using the placeholder parameters and 1 V peak command.

The original ideal excitation force is 0.100000 N.

Therefore, the VCA command voltage must be adjusted after selecting the actual actuator if an exact 0.100 N peak excitation is required.

---

# Project Directory Structure

DIA-TISSUE-MATLAB-SIMULATION/

    01_Baseline_Mechanical_Response/

        experiment_baseline.m

        README.md

        results/

    02_Stiffness_Comparison/

        experiment_stiffness.m

        README.md

        results/

    03_Frequency_Sweep/

        experiment_frequency_sweep.m

        README.md

        results/

    04_FFT_Analysis/

        experiment_fft.m

        fft_analysis.m

        README.md

        results/

    05_Sensor_Simulation/

        experiment_sensor.m

        sensor_model.m

        README.md

        results/

    06_Noise_SNR_Analysis/

        experiment_noise_snr.m

        README.md

        results/

    07_Contact_Force_Sensitivity/

        experiment_contact_force.m

        README.md

        results/

    08_Load_Cell_Validation/

        experiment_load_cell.m

        README.md

        results/

    09_VCA_Electrical_Test/

        experiment_vca.m

        README.md

        results/

    common/

        simulation_parameters.m

        tissue_model.m

    README.md

---

# Common Files

## simulation_parameters.m

This file contains the common simulation parameters and the three mechanical models.

The common parameters currently include:

- Effective mass
- Excitation frequency
- Force amplitude
- Model A stiffness and damping
- Model B stiffness and damping
- Model C stiffness and damping
- Natural frequency calculations
- Damping ratio calculations

## tissue_model.m

This file provides the common mechanical model used by the experiments that require the mass-spring-damper representation.

Important:

The common files should remain unchanged unless a deliberate project-wide model change is required.

Changing common parameters may change the outputs of multiple experiments.

---

# Signal Processing

The project includes FFT-based frequency analysis.

The FFT processing includes:

1. DC removal
2. Hann window
3. FFT calculation
4. Coherent-gain correction
5. Single-sided spectrum calculation
6. Frequency-axis generation
7. Dominant-frequency detection

The current FFT test successfully detects:

Expected frequency = 30.00 Hz

Detected frequency = 30.00 Hz

---

# Key Simulation Findings

The nine experiments collectively demonstrate the following engineering relationships:

### 1. Mechanical Response

The mass-spring-damper model produces displacement, velocity, and acceleration responses under sinusoidal excitation.

### 2. Stiffness

Increasing stiffness changes the natural frequency of the mechanical system.

### 3. Frequency Response

The frequency sweep demonstrates that the peak acceleration response shifts toward higher frequencies as stiffness increases.

### 4. FFT

The FFT successfully identifies the simulated 30 Hz excitation frequency.

### 5. Sensor Modeling

The accelerometer simulation demonstrates the effects of range, resolution, bandwidth, noise, bias, and quantization.

### 6. Noise

Increasing sensor noise density increases measurement error and decreases SNR.

### 7. Contact Force

Contact force changes the assumed effective stiffness and therefore changes the mechanical response.

### 8. Load Cell

Load-cell validation can be used as an engineering-level mechanism for rejecting insufficient or excessive contact.

### 9. VCA

The VCA electrical model provides a link between voltage command, current, and actuator force.

---

# Current Engineering Simulation Flow

The current simulation architecture can be represented as:

VCA Electrical Command
        |
        v
Electrical Impedance
        |
        v
Actuator Current
        |
        v
Actuator Force
        |
        v
Mechanical Tissue Model
        |
        v
Displacement / Velocity / Acceleration
        |
        v
Sensor Model
        |
        +----------------------+
        |                      |
        v                      v
Sensor Noise              Load Cell
        |                      |
        v                      v
Signal Processing       Contact Validation
        |
        v
FFT / SNR Analysis
        |
        v
Mechanical Response Features

---

# Research and Development Status

The current repository represents a simulation-stage engineering framework.

Completed simulation areas:

- Mechanical baseline model
- Stiffness comparison
- Frequency sweep
- FFT analysis
- Sensor simulation
- Noise and SNR analysis
- Contact-force sensitivity
- Load-cell validation
- VCA electrical test

Future development can include:

- Exact VCA selection
- Hardware actuator characterization
- Real accelerometer integration
- Real load-cell integration
- Experimental calibration
- Real-time data acquisition
- Hardware-in-the-loop testing
- Experimental tissue measurements
- Model validation using measured data

---

# Limitations

The entire repository is currently based on simulation models and assumed parameters.

The following limitations apply:

1. The mechanical model is a simplified lumped mass-spring-damper representation.
2. Biological tissue is more complex than the implemented model.
3. Tissue properties may be nonlinear and frequency-dependent.
4. Several sensor and actuator parameters are assumed.
5. The VCA parameters are placeholder values.
6. The load-cell limits are research simulation parameters.
7. The sensor noise models are simplified.
8. Real hardware behavior may differ from simulation.
9. No clinical thresholds are established by this repository.
10. No diagnostic classification is performed by these simulations.
11. Experimental hardware validation is required.

---

# Simulation Disclaimer

This repository is intended for engineering research, simulation, algorithm development, and feasibility analysis.

All mechanical, sensor, actuator, contact-force, noise, and validation parameters are simulation assumptions unless explicitly identified as experimentally measured.

The models and outputs in this repository must NOT be interpreted as:

- Clinical measurements
- Clinical limits
- Diagnostic thresholds
- Disease-stage classifications
- Medical diagnoses
- Validated patient-specific results

Physical hardware testing and appropriate experimental validation are required before drawing conclusions from real-world measurements.