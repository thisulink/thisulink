%% THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM
% Experiment 5: Dual ADXL355 20-Bit Accelerometer Sensor Simulation
% Hardware: Dual Analog Devices ADXL355 Triaxial Digital Pickups
% SIH 2026 Grand Finale - THISULINK Diagnostic Verification

clear;
clc;
close all;

%% Path Setup
expDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(expDir);
addpath(fullfile(projectRoot, 'common'));
addpath(expDir);

%% Load Calibrated Parameters
simulation_parameters;

%% Setup Sensor Hardware Struct
params.range_g       = sensor_range_g;    % 2.048 g
params.bits          = sensor_bits;       % 20 bits
params.bandwidth     = sensor_bandwidth;  % 150 Hz
params.noise_density = sensor_noise_dens; % 25 ug/sqrt(Hz) = 0.000245 m/s^2/sqrt(Hz)
params.bias          = sensor_bias;       % 0.005 m/s^2

%% Generate Ground Truth Plantar Exciter Motion
x0 = [0; 0];
[t_sim, X] = ode45(@(tt, x) tissue_model(tt, x, m, c_A, k_A, F0, f_exc), t, x0);
disp_source = X(:, 1);
vel_source  = X(:, 2);
force       = F0 * sin(2 * pi * f_exc * t_sim);
acc_source  = (force - c_A * vel_source - k_A * disp_source) / m;

%% Propagate Shear Waves to Dual Pickups
% Proximal sensor at x1 = 105 mm
[acc_sensor1_true, wave1] = shear_wave_propagation_model(t_sim, acc_source, x_sensor1, ...
    mu_A, eta_A, rho_tissue, f_exc);

% Distal sensor at x2 = 145 mm (dx = 40 mm)
[acc_sensor2_true, wave2] = shear_wave_propagation_model(t_sim, acc_source, x_sensor2, ...
    mu_A, eta_A, rho_tissue, f_exc);

%% Pass Through Dual ADXL355 Emulators
rng(42); % Reproducible sensor noise
[acc_sensor1_meas, info1] = sensor_model(acc_sensor1_true, params);
[acc_sensor2_meas, info2] = sensor_model(acc_sensor2_true, params);

%% Error & SNR Metrics
err1 = acc_sensor1_meas - acc_sensor1_true;
err2 = acc_sensor2_meas - acc_sensor2_true;

rms_true1  = rms(acc_sensor1_true);
rms_true2  = rms(acc_sensor2_true);
rms_error1 = rms(err1);
rms_error2 = rms(err2);

snr1 = 20 * log10(rms_true1 / rms_error1);
snr2 = 20 * log10(rms_true2 / rms_error2);

%% Time-of-Flight (ToF) & Velocity Calculation
expected_ToF = (x_sensor2 - x_sensor1) / wave1.cs; % 40 mm / 3.72 m/s ~ 10.75 ms

%% Console Output
fprintf('\n========================================================================\n');
fprintf('  THISULINK EXPERIMENT 05: DUAL ADXL355 ACCELEROMETER SIMULATION        \n');
fprintf('========================================================================\n');
fprintf('Sensor Model                  : Analog Devices ADXL355 (20-bit)\n');
fprintf('Full-Scale Range              : +/- %.3f g (+/- %.2f m/s^2)\n', params.range_g, info1.range_limit);
fprintf('Digital ADC Resolution        : %d bits\n', params.bits);
fprintf('Quantization Resolution       : %.2e m/s^2 (%.2f ug/LSB)\n', ...
    info1.quantization_step, info1.quantization_step_ug);
fprintf('Noise Density                 : %.2e m/s^2/sqrt(Hz) (25 ug/sqrt(Hz))\n', params.noise_density);
fprintf('Internal Analog Bandwidth     : %.1f Hz\n', params.bandwidth);
fprintf('Theoretical Noise Floor (RMS) : %.4f m/s^2\n', info1.noise_rms);
fprintf('------------------------------------------------------------------------\n');
fprintf('PROXIMAL SENSOR (x1 = %.0f mm):\n', x_sensor1 * 1000);
fprintf('  True Signal RMS             : %.4f m/s^2\n', rms_true1);
fprintf('  Measurement Error RMS       : %.4f m/s^2\n', rms_error1);
fprintf('  Signal-to-Noise Ratio (SNR) : %.2f dB\n', snr1);
fprintf('DISTAL SENSOR (x2 = %.0f mm, dx = %.0f mm):\n', x_sensor2 * 1000, delta_x * 1000);
fprintf('  True Signal RMS             : %.4f m/s^2\n', rms_true2);
fprintf('  Measurement Error RMS       : %.4f m/s^2\n', rms_error2);
fprintf('  Signal-to-Noise Ratio (SNR) : %.2f dB\n', snr2);
fprintf('INTER-SENSOR WAVE PROPERTIES:\n');
fprintf('  Plantar Shear Speed cs      : %.2f m/s\n', wave1.cs);
fprintf('  Theoretical Wave ToF Delay  : %.2f ms\n', expected_ToF * 1000);
fprintf('========================================================================\n\n');

%% Results Directory
resultsFolder = fullfile(expDir, 'results');
if ~exist(resultsFolder, 'dir')
    mkdir(resultsFolder);
end

%% Plot 1: True vs Measured Dual Pickup Waveforms
figure('Name', 'THISULINK - Dual ADXL355 Sensor Signals', 'Color', 'w');
subplot(2, 1, 1);
plot(t_sim(1:600) * 1000, acc_sensor1_true(1:600), 'b', 'LineWidth', 1.5);
hold on;
plot(t_sim(1:600) * 1000, acc_sensor1_meas(1:600), 'k--', 'LineWidth', 1.0);
ylabel('Acc (m/s^2)');
title(sprintf('Proximal Sensor 1 (x_1 = %0.0f mm) — SNR = %.1f dB', x_sensor1*1000, snr1));
legend('True Physical Wave', 'ADXL355 Digitized Output', 'Location', 'northeast');
grid on;

subplot(2, 1, 2);
plot(t_sim(1:600) * 1000, acc_sensor2_true(1:600), 'r', 'LineWidth', 1.5);
hold on;
plot(t_sim(1:600) * 1000, acc_sensor2_meas(1:600), 'k--', 'LineWidth', 1.0);
xlabel('Time (ms)');
ylabel('Acc (m/s^2)');
title(sprintf('Distal Sensor 2 (x_2 = %0.0f mm, dx = %0.0f mm) — SNR = %.1f dB [ToF delay = %.1f ms]', ...
    x_sensor2*1000, delta_x*1000, snr2, expected_ToF*1000));
legend('True Physical Wave', 'ADXL355 Digitized Output', 'Location', 'northeast');
grid on;
saveas(gcf, fullfile(resultsFolder, 'dual_adxl355_waveforms.png'));

%% Plot 2: Measurement Residual Error
figure('Name', 'THISULINK - ADXL355 Measurement Error', 'Color', 'w');
plot(t_sim(1:600) * 1000, err1(1:600), 'Color', [0.85 0.33 0.10], 'LineWidth', 1.0);
hold on;
plot(t_sim(1:600) * 1000, err2(1:600), 'Color', [0.47 0.67 0.19], 'LineWidth', 1.0);
xlabel('Time (ms)');
ylabel('Residual Error (m/s^2)');
title('THISULINK ADXL355 Digitization & Noise Residuals');
legend('Proximal Sensor 1 Error', 'Distal Sensor 2 Error', 'Location', 'best');
grid on;
saveas(gcf, fullfile(resultsFolder, 'measurement_error.png'));
