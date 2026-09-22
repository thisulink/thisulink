%% THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM
% Experiment 6: Sensor Noise Floor & SNR Robustness Analysis
% Validates ADXL355 Ultra-Low Noise Performance Across Noise Regimes
% SIH 2026 Grand Finale - THISULINK Diagnostic Verification

clear;
clc;
close all;

%% Path Setup
expDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(expDir);
addpath(fullfile(projectRoot, 'common'));
addpath(fullfile(projectRoot, '04_FFT_Analysis'));

%% Load Calibrated Parameters
simulation_parameters;

%% Sensor Baseline Config
bandwidth = sensor_bandwidth; % 150 Hz
bias = sensor_bias;           % 0.005 m/s^2

%% Noise Density Sweep (from pristine laboratory grade to extreme industrial noise)
% ADXL355 nominal = 0.000245 m/s^2/sqrt(Hz) (25 ug/sqrt(Hz))
noise_density_levels = [
    0.00010   % Ultra-quiet laboratory seismic grade (~10 ug/sqrt(Hz))
    0.000245  % THISULINK ADXL355 Nominal (25 ug/sqrt(Hz))
    0.00100   % Standard MEMS consumer sensor (~100 ug/sqrt(Hz))
    0.00500   % Noisy commercial grade (~500 ug/sqrt(Hz))
    0.02000   % Severe vibrational interference (~2000 ug/sqrt(Hz))
    0.08000   % Extreme noise artifact limit
];

numLevels = length(noise_density_levels);

%% Generate Plantar Sensor Signal (Distal Pickup 2 at x2 = 145 mm)
x0 = [0; 0];
[t_sim, X] = ode45(@(tt, x) tissue_model(tt, x, m, c_A, k_A, F0, f_exc), t, x0);
disp_source = X(:, 1);
vel_source  = X(:, 2);
force       = F0 * sin(2 * pi * f_exc * t_sim);
acc_source  = (force - c_A * vel_source - k_A * disp_source) / m;

% Propagate to Distal Pickup (worst-case attenuation)
[true_acc, ~] = shear_wave_propagation_model(t_sim, acc_source, x_sensor2, ...
    mu_A, eta_A, rho_tissue, f_exc);

true_rms = rms(true_acc);

%% Preallocate Metrics
error_rms          = zeros(numLevels, 1);
snr_db             = zeros(numLevels, 1);
detected_frequency = zeros(numLevels, 1);
phase_error_deg    = zeros(numLevels, 1);

%% Run Noise Sweep
rng(100);

for i = 1:numLevels
    nd = noise_density_levels(i);
    noise_rms = nd * sqrt(bandwidth);
    noise = noise_rms .* randn(size(true_acc));
    
    measured_acc = true_acc + bias + noise;
    
    % Error RMS
    err_sig = measured_acc - true_acc;
    error_rms(i) = rms(err_sig);
    
    % SNR (dB)
    snr_db(i) = 20 * log10(true_rms / error_rms(i));
    
    % Peak Frequency Detection via FFT
    [f_fft, mag_fft] = fft_analysis(measured_acc, fs);
    mag_fft(1) = 0; % Remove DC
    [~, max_idx] = max(mag_fft);
    detected_frequency(i) = f_fft(max_idx);
    
    % Phase estimation error at fundamental frequency (f_exc = 50 Hz)
    [~, f0_idx] = min(abs(f_fft - f_exc));
    
    % Analytical phase difference
    phase_true = angle(sum(true_acc .* exp(-1i * 2 * pi * f_exc * t_sim)));
    phase_meas = angle(sum((measured_acc - mean(measured_acc)) .* exp(-1i * 2 * pi * f_exc * t_sim)));
    phase_error_deg(i) = abs(phase_meas - phase_true) * (180 / pi);
end

%% Console Output
fprintf('\n========================================================================\n');
fprintf('  THISULINK EXPERIMENT 06: SENSOR NOISE FLOOR & SNR ROBUSTNESS         \n');
fprintf('========================================================================\n');
fprintf('Plantar Pickup Location       : Distal Sensor 2 (x2 = %.0f mm)\n', x_sensor2 * 1000);
fprintf('Diagnostic Frequency          : %.1f Hz\n', f_exc);
fprintf('Distal True Signal RMS        : %.4f m/s^2\n', true_rms);
fprintf('ADXL355 Nominal Noise Density : %.2e m/s^2/sqrt(Hz) (25 ug/sqrt(Hz))\n', sensor_noise_dens);
fprintf('------------------------------------------------------------------------\n');
fprintf('Noise Density\tNoise RMS\tError RMS\tSNR(dB)\tDetected f\tPhase Error\n');
fprintf('(m/s^2/rtHz)\t(m/s^2)\t\t(m/s^2)\t\t\t(Hz)\t\t(deg)\n');
fprintf('------------------------------------------------------------------------\n');
for i = 1:numLevels
    fprintf('%.6f\t%.4f\t\t%.4f\t\t%.2f\t%.2f\t\t%.3f\n', ...
        noise_density_levels(i), ...
        noise_density_levels(i)*sqrt(bandwidth), ...
        error_rms(i), ...
        snr_db(i), ...
        detected_frequency(i), ...
        phase_error_deg(i));
end
fprintf('========================================================================\n\n');

%% Results Directory
resultsFolder = fullfile(expDir, 'results');
if ~exist(resultsFolder, 'dir')
    mkdir(resultsFolder);
end

%% Plot 1: SNR vs Noise Density
figure('Name', 'THISULINK - SNR vs Noise Density', 'Color', 'w');
semilogx(noise_density_levels * 1e6 / 9.80665, snr_db, 'o-b', 'LineWidth', 1.8, 'MarkerFaceColor', 'b');
hold on;
xline(25, '--r', 'ADXL355 Nominal (25 \mug/\surdHz)', 'LineWidth', 1.5);
yline(20, ':k', 'Clinical Phase Threshold (20 dB)', 'LineWidth', 1.2);
xlabel('Sensor Noise Density (\mug/\surdHz)');
ylabel('Signal-to-Noise Ratio (dB)');
title('THISULINK Plantar SWE Signal-to-Noise Ratio vs Accelerometer Noise Floor');
grid on;
saveas(gcf, fullfile(resultsFolder, 'snr_vs_noise.png'));

%% Plot 2: Phase Tracking Error vs Noise Floor
figure('Name', 'THISULINK - Phase Error vs Noise', 'Color', 'w');
loglog(noise_density_levels * 1e6 / 9.80665, phase_error_deg, 's-r', 'LineWidth', 1.8, 'MarkerFaceColor', 'r');
hold on;
xline(25, '--b', 'ADXL355 Nominal (25 \mug/\surdHz)', 'LineWidth', 1.5);
yline(1.0, ':k', 'Max Allowable Phase Jitter (1.0^\circ)', 'LineWidth', 1.2);
xlabel('Sensor Noise Density (\mug/\surdHz)');
ylabel('Phase Tracking Error (degrees)');
title('THISULINK Wave Phase Error vs Sensor Noise Density');
grid on;
saveas(gcf, fullfile(resultsFolder, 'phase_error_vs_noise.png'));

%% Plot 3: Detected Frequency Stability
figure('Name', 'THISULINK - Frequency Tracking', 'Color', 'w');
semilogx(noise_density_levels * 1e6 / 9.80665, detected_frequency, '^-g', 'LineWidth', 1.8, 'MarkerFaceColor', 'g');
hold on;
yline(f_exc, '--k', sprintf('True f_0 = %.0f Hz', f_exc), 'LineWidth', 1.2);
xlabel('Sensor Noise Density (\mug/\surdHz)');
ylabel('Detected Frequency (Hz)');
title('THISULINK Frequency Tracking Robustness Under Sensor Noise');
grid on;
saveas(gcf, fullfile(resultsFolder, 'detected_frequency_vs_noise.png'));
