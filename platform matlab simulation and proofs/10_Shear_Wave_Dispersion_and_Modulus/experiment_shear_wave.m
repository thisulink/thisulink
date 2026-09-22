%% THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM
% Experiment 10: Shear Wave Dispersion, Phase Velocity & Young's Modulus
% Dual-Pickup Accelerometer Phase-Difference Elastography Pipeline
% SIH 2026 Grand Finale - THISULINK Diagnostic Verification

clear;
clc;
close all;

%% Path Setup
expDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(expDir);
addpath(fullfile(projectRoot, 'common'));
addpath(fullfile(projectRoot, '04_FFT_Analysis'));
addpath(fullfile(projectRoot, '05_Sensor_Simulation'));

%% Load Calibrated Parameters
simulation_parameters;

%% Setup Dual Pickup Geometry
% Sensor 1 (Proximal): x1 = 105 mm
% Sensor 2 (Distal):   x2 = 145 mm (dx = 40 mm)
x1 = x_sensor1;
x2 = x_sensor2;
dx = delta_x; % 0.040 m

%% Diagnostic Classes Definition
classes = {
    struct('name', 'Healthy Control', 'k', k_A, 'c', c_A, 'mu', mu_A, 'eta', eta_A, 'cs_true', cs_A, 'E_true', E_A), ...
    struct('name', 'Early Glycation', 'k', k_B, 'c', c_B, 'mu', mu_B, 'eta', eta_B, 'cs_true', cs_B, 'E_true', E_B), ...
    struct('name', 'Diabetic Neuropathy', 'k', k_C, 'c', c_C, 'mu', mu_C, 'eta', eta_C, 'cs_true', cs_C, 'E_true', E_C)
};
numClasses = length(classes);

%% Run Simulation Across Diagnostic Classes at 50 Hz Nominal
x0 = [0; 0];
sensor_params.range_g       = sensor_range_g;
sensor_params.bits          = sensor_bits;
sensor_params.bandwidth     = sensor_bandwidth;
sensor_params.noise_density = sensor_noise_dens;
sensor_params.bias          = sensor_bias;

cs_estimated = zeros(numClasses, 1);
E_estimated  = zeros(numClasses, 1);
ToF_xcorr_ms = zeros(numClasses, 1);
phase_delays = zeros(numClasses, 1);

time_signals_1 = zeros(length(t), numClasses);
time_signals_2 = zeros(length(t), numClasses);

w0 = 2 * pi * f_exc;

for i = 1:numClasses
    cl = classes{i};
    
    % Exciter motion
    [t_sim, X] = ode45(@(tt, x) tissue_model(tt, x, m, cl.c, cl.k, F0, f_exc), t, x0);
    disp_src = X(:, 1);
    vel_src  = X(:, 2);
    force    = F0 * sin(w0 * t_sim);
    acc_src  = (force - cl.c * vel_src - cl.k * disp_src) / m;
    
    % Wave propagation to Sensor 1 and Sensor 2
    [u1_true, ~] = shear_wave_propagation_model(t_sim, acc_src, x1, cl.mu, cl.eta, rho_tissue, f_exc);
    [u2_true, ~] = shear_wave_propagation_model(t_sim, acc_src, x2, cl.mu, cl.eta, rho_tissue, f_exc);
    
    % Dual ADXL355 digitization
    rng(i * 10);
    [u1_meas, ~] = sensor_model(u1_true, sensor_params);
    [u2_meas, ~] = sensor_model(u2_true, sensor_params);
    
    time_signals_1(:, i) = u1_meas;
    time_signals_2(:, i) = u2_meas;
    
    % Method 1: Time-of-Flight via Cross-Correlation
    [corr_vals, lags] = xcorr(u2_meas - mean(u2_meas), u1_meas - mean(u1_meas), round(0.05 * fs));
    [~, max_lag_idx] = max(corr_vals);
    lag_samples = lags(max_lag_idx);
    ToF_sec = lag_samples / fs;
    ToF_xcorr_ms(i) = ToF_sec * 1000;
    
    % Method 2: Dual Pickup Phase Difference Method at f_exc
    % Extract complex Fourier component at 50 Hz
    dt = t_sim(2) - t_sim(1);
    F_comp1 = sum((u1_meas - mean(u1_meas)) .* exp(-1i * w0 * t_sim)) * dt;
    F_comp2 = sum((u2_meas - mean(u2_meas)) .* exp(-1i * w0 * t_sim)) * dt;
    
    dphi = angle(F_comp1) - angle(F_comp2);
    % Unwrap into positive delay
    if dphi < 0
        dphi = dphi + 2*pi;
    end
    phase_delays(i) = dphi;
    
    % Reconstruct shear wave speed: cs = (w * dx) / dphi
    cs_est = (w0 * dx) / dphi;
    cs_estimated(i) = cs_est;
    
    % Reconstruct Young's Modulus: E = 3 * rho * cs^2
    E_est = (3 * rho_tissue * (cs_est^2)) / 1000; % kPa
    E_estimated(i) = E_est;
end

%% Viscoelastic Dispersion Curve Across 20 to 150 Hz
f_disp_sweep = 20:2:150;
numSweep = length(f_disp_sweep);
cs_disp_matrix = zeros(numSweep, numClasses);

for i = 1:numClasses
    cl = classes{i};
    for s = 1:numSweep
        w_curr = 2 * pi * f_disp_sweep(s);
        G_mag  = sqrt(cl.mu^2 + (w_curr * cl.eta)^2);
        cs_disp_matrix(s, i) = sqrt((2 * G_mag^2) / (rho_tissue * (cl.mu + G_mag)));
    end
end

%% Console Output
fprintf('\n========================================================================\n');
fprintf('  THISULINK EXPERIMENT 10: PLANTAR SWE DISPERSION & MODULUS RECONSTRUCT \n');
fprintf('========================================================================\n');
fprintf('Gauge Separation Distance dx  : %.1f mm (Proximal = %.0f mm, Distal = %.0f mm)\n', ...
    dx*1000, x1*1000, x2*1000);
fprintf('Diagnostic Frequency (f)      : %.1f Hz\n', f_exc);
fprintf('Plantar Tissue Density (rho)  : %.1f kg/m^3\n', rho_tissue);
fprintf('------------------------------------------------------------------------\n');
fprintf('Class\t\t\tTrue cs\tEst cs\tTrue E\tEst E\tToF Delay\tError\n');
fprintf('\t\t\t(m/s)\t(m/s)\t(kPa)\t(kPa)\t(ms)\t\t(%%)\n');
fprintf('------------------------------------------------------------------------\n');
for i = 1:numClasses
    err_pct = abs(E_estimated(i) - classes{i}.E_true/1000) / (classes{i}.E_true/1000) * 100;
    fprintf('%-20s\t%.2f\t%.2f\t%.1f\t%.1f\t%.2f ms\t\t%.2f%%\n', ...
        classes{i}.name, classes{i}.cs_true, cs_estimated(i), ...
        classes{i}.E_true/1000, E_estimated(i), ToF_xcorr_ms(i), err_pct);
end
fprintf('========================================================================\n\n');

%% Results Directory
resultsFolder = fullfile(expDir, 'results');
if ~exist(resultsFolder, 'dir')
    mkdir(resultsFolder);
end

colors = [0.0 0.45 0.74; 0.85 0.33 0.10; 0.64 0.08 0.18];

%% Plot 1: Dual Pickup Waveforms (Healthy vs Neuropathic)
figure('Name', 'THISULINK - Dual Pickup Phase Delay', 'Color', 'w');
subplot(2, 1, 1);
plot(t(1:400)*1000, time_signals_1(1:400, 1), 'b', 'LineWidth', 1.5);
hold on;
plot(t(1:400)*1000, time_signals_2(1:400, 1), 'r--', 'LineWidth', 1.5);
ylabel('Acc (m/s^2)');
title('Class 1: Healthy Control — Slow Shear Speed (cs = 3.72 m/s, Large ToF Delay)');
legend('Proximal Pickup (105 mm)', 'Distal Pickup (145 mm)', 'Location', 'northeast');
grid on;

subplot(2, 1, 2);
plot(t(1:400)*1000, time_signals_1(1:400, 3), 'b', 'LineWidth', 1.5);
hold on;
plot(t(1:400)*1000, time_signals_2(1:400, 3), 'r--', 'LineWidth', 1.5);
xlabel('Time (ms)');
ylabel('Acc (m/s^2)');
title('Class 3: Diabetic Neuropathy — Fast Shear Speed (cs = 8.05 m/s, Rapid ToF Arrival)');
legend('Proximal Pickup (105 mm)', 'Distal Pickup (145 mm)', 'Location', 'northeast');
grid on;
saveas(gcf, fullfile(resultsFolder, 'shear_wave_dual_pickups.png'));

%% Plot 2: Reconstructed Elastic Modulus E
figure('Name', 'THISULINK - Modulus Reconstruction', 'Color', 'w');
bar_data = [ [classes{1}.E_true, classes{2}.E_true, classes{3}.E_true]'/1000, E_estimated ];
b = bar(bar_data);
b(1).FaceColor = [0.2 0.2 0.2];
b(2).FaceColor = [0.47 0.67 0.19];
set(gca, 'XTick', 1:3, 'XTickLabel', {'Healthy Control', 'Early Glycation', 'Diabetic Neuropathy'});
ylabel('Young Modulus E (kPa)');
title('THISULINK Plantar Shear Wave Modulus: True vs Reconstructed');
legend('Ground Truth Modulus', 'THISULINK Dual-ADXL355 Reconstructed', 'Location', 'northwest');
grid on;
for i = 1:3
    text(i - 0.14, bar_data(i, 1) + 6, sprintf('%.1f', bar_data(i, 1)), 'FontWeight', 'bold');
    text(i + 0.14, bar_data(i, 2) + 6, sprintf('%.1f', bar_data(i, 2)), 'FontWeight', 'bold', 'Color', [0 0.5 0]);
end
saveas(gcf, fullfile(resultsFolder, 'modulus_reconstruction_validation.png'));

%% Plot 3: Viscoelastic Kelvin-Voigt Dispersion Curves
figure('Name', 'THISULINK - Dispersion Curves', 'Color', 'w');
hold on;
for i = 1:numClasses
    plot(f_disp_sweep, cs_disp_matrix(:, i), 'LineWidth', 2.0, 'Color', colors(i, :));
end
xlabel('Frequency (Hz)');
ylabel('Phase Velocity c_s(\omega) (m/s)');
title('THISULINK Plantar Tissue Viscoelastic Shear Wave Dispersion');
legend({'Healthy Control (\mu=14.5 kPa, \eta=12 Pa\cdots)', ...
        'Early Glycation (\mu=32.0 kPa, \eta=18.5 Pa\cdots)', ...
        'Diabetic Neuropathy (\mu=68.0 kPa, \eta=28 Pa\cdots)'}, 'Location', 'northwest');
grid on;
saveas(gcf, fullfile(resultsFolder, 'shear_wave_dispersion_curves.png'));
