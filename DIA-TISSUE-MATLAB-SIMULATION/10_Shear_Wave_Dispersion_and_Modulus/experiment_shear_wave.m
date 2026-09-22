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
    
    [t_sim, X] = ode45(@(tt, x) tissue_model(tt, x, m, cl.c, cl.k, F0, f_exc), t, x0);
    disp_src = X(:, 1);
    vel_src  = X(:, 2);
    force    = F0 * sin(w0 * t_sim);
    acc_src  = (force - cl.c * vel_src - cl.k * disp_src) / m;
    
    [u1_true, ~] = shear_wave_propagation_model(t_sim, acc_src, x1, cl.mu, cl.eta, rho_tissue, f_exc);
    [u2_true, ~] = shear_wave_propagation_model(t_sim, acc_src, x2, cl.mu, cl.eta, rho_tissue, f_exc);
    
    rng(i * 10);
    [u1_meas, ~] = sensor_model(u1_true, sensor_params);
    [u2_meas, ~] = sensor_model(u2_true, sensor_params);
    
    time_signals_1(:, i) = u1_meas;
    time_signals_2(:, i) = u2_meas;
    
    [corr_vals, lags] = xcorr(u2_meas - mean(u2_meas), u1_meas - mean(u1_meas), round(0.05 * fs));
    [~, max_lag_idx] = max(corr_vals);
    lag_samples = lags(max_lag_idx);
    ToF_sec = lag_samples / fs;
    ToF_xcorr_ms(i) = ToF_sec * 1000;
    
    dt = t_sim(2) - t_sim(1);
    F_comp1 = sum((u1_meas - mean(u1_meas)) .* exp(-1i * w0 * t_sim)) * dt;
    F_comp2 = sum((u2_meas - mean(u2_meas)) .* exp(-1i * w0 * t_sim)) * dt;
    
    dphi = angle(F_comp1) - angle(F_comp2);
    if dphi < 0
        dphi = dphi + 2*pi;
    end
    phase_delays(i) = dphi;
    
    cs_est = (w0 * dx) / dphi;
    cs_estimated(i) = cs_est;
    
    E_est = (3 * rho_tissue * (cs_est^2)) / 1000;
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
fprintf('Gauge Separation Distance dx  : %.1f mm\n', dx*1000);
fprintf('Diagnostic Frequency (f)      : %.1f Hz\n', f_exc);
fprintf('Plantar Tissue Density (rho)  : %.1f kg/m^3\n', rho_tissue);
fprintf('------------------------------------------------------------------------\n');
for i = 1:numClasses
    err_pct = abs(E_estimated(i) - classes{i}.E_true/1000) / (classes{i}.E_true/1000) * 100;
    fprintf('%-20s\tTrue: %.2f m/s\tEst: %.2f m/s\tTrue E: %.1f kPa\tEst E: %.1f kPa\tErr: %.2f%%\n', ...
        classes{i}.name, classes{i}.cs_true, cs_estimated(i), ...
        classes{i}.E_true/1000, E_estimated(i), err_pct);
end
fprintf('========================================================================\n\n');

resultsFolder = fullfile(expDir, 'results');
if ~exist(resultsFolder, 'dir')
    mkdir(resultsFolder);
end
