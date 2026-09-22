%% THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM
% Experiment 3: Chirp Frequency Response Sweep (10 - 300 Hz)
% Dynamic Mechanical Transfer Function & Resonance Peak Tracking
% SIH 2026 Grand Finale - THISULINK Diagnostic Verification

clear;
clc;
close all;

%% Path Setup
expDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(expDir);
addpath(fullfile(projectRoot, 'common'));

%% Load Calibrated Parameters
simulation_parameters;

%% Setup Frequency Sweep (10 to 300 Hz diagnostic chirp band)
frequencies = f_start:frequency_step:f_end;  % 10:1:300 Hz
numFreq = length(frequencies);

k_values = [k_A, k_B, k_C];
c_values = [c_A, c_B, c_C];

class_names = {
    'Class 1: Healthy Control'
    'Class 2: Early Glycation'
    'Class 3: Diabetic Neuropathy'
};
numClasses = 3;

%% Storage Preallocation
acc_amp   = zeros(numFreq, numClasses);
disp_amp  = zeros(numFreq, numClasses);
phase_deg = zeros(numFreq, numClasses);

%% Steady-State Transfer Function Calculation
% Dynamic compliance FRF: H_x(w) = 1 / [(k - m*w^2) + j*(c*w)]
% Acceleration FRF:       H_a(w) = -w^2 * H_x(w)

for c_idx = 1:numClasses
    k_curr = k_values(c_idx);
    c_curr = c_values(c_idx);
    
    for f_idx = 1:numFreq
        f = frequencies(f_idx);
        w = 2 * pi * f;
        
        dynamic_stiffness = (k_curr - m * w^2) + 1i * (c_curr * w);
        Hx = 1 / dynamic_stiffness;
        Ha = -(w^2) * Hx;
        
        disp_amp(f_idx, c_idx)  = abs(Hx) * F0;
        acc_amp(f_idx, c_idx)   = abs(Ha) * F0;
        phase_deg(f_idx, c_idx) = angle(Ha) * (180 / pi);
    end
end

%% Find Peak Resonance Frequencies
peak_acc_val  = zeros(numClasses, 1);
peak_freq_val = zeros(numClasses, 1);

for c_idx = 1:numClasses
    [peak_acc_val(c_idx), max_idx] = max(acc_amp(:, c_idx));
    peak_freq_val(c_idx) = frequencies(max_idx);
end

%% Theoretical Resonance Frequencies
fn = (1 / (2 * pi)) .* sqrt(k_values ./ m);

%% Console Output
fprintf('\n========================================================================\n');
fprintf('  THISULINK EXPERIMENT 03: CHIRP FREQUENCY SWEEP (10 - 300 Hz)          \n');
fprintf('========================================================================\n');
fprintf('Chirp Bandwidth           : %.0f Hz - %.0f Hz\n', f_start, f_end);
fprintf('Dynamic Force Amplitude   : %.3f N (100 mN)\n', F0);
fprintf('Actuator Moving Mass      : %.4f kg (45 g)\n', m);
fprintf('------------------------------------------------------------------------\n');
for c_idx = 1:numClasses
    fprintf('%s:\n', class_names{c_idx});
    fprintf('  Stiffness k             : %.1f N/m\n', k_values(c_idx));
    fprintf('  Theoretical fn          : %.2f Hz\n', fn(c_idx));
    fprintf('  Simulated Peak Acc Freq : %.2f Hz\n', peak_freq_val(c_idx));
    fprintf('  Simulated Peak Acc Amp  : %.4f m/s^2 (%.3f g)\n', ...
        peak_acc_val(c_idx), peak_acc_val(c_idx)/9.80665);
end
fprintf('========================================================================\n\n');

%% Results Directory
resultsFolder = fullfile(expDir, 'results');
if ~exist(resultsFolder, 'dir')
    mkdir(resultsFolder);
end

colors = [0.0 0.45 0.74; 0.85 0.33 0.10; 0.64 0.08 0.18];

%% Plot 1: Acceleration Frequency Response
figure('Name', 'THISULINK - Acceleration Frequency Response', 'Color', 'w');
hold on;
for c_idx = 1:numClasses
    plot(frequencies, acc_amp(:, c_idx), 'LineWidth', 1.8, 'Color', colors(c_idx, :));
    plot(peak_freq_val(c_idx), peak_acc_val(c_idx), 'o', 'MarkerSize', 8, ...
        'MarkerFaceColor', colors(c_idx, :), 'MarkerEdgeColor', 'k');
end
xlabel('Chirp Excitation Frequency (Hz)');
ylabel('Acceleration Amplitude (m/s^2)');
title('THISULINK Acceleration Frequency Response (10 - 300 Hz Chirp)');
legend(class_names, 'Location', 'northeast');
grid on;
saveas(gcf, fullfile(resultsFolder, 'acceleration_frequency_response.png'));

%% Plot 2: Displacement Frequency Response
figure('Name', 'THISULINK - Displacement Frequency Response', 'Color', 'w');
hold on;
for c_idx = 1:numClasses
    plot(frequencies, disp_amp(:, c_idx) * 1000, 'LineWidth', 1.8, 'Color', colors(c_idx, :));
end
xlabel('Chirp Excitation Frequency (Hz)');
ylabel('Dynamic Displacement (mm)');
title('THISULINK Plantar Dynamic Displacement vs Frequency');
legend(class_names, 'Location', 'northeast');
grid on;
saveas(gcf, fullfile(resultsFolder, 'displacement_frequency_response.png'));

%% Plot 3: Phase Response
figure('Name', 'THISULINK - Phase Response', 'Color', 'w');
hold on;
for c_idx = 1:numClasses
    plot(frequencies, phase_deg(:, c_idx), 'LineWidth', 1.8, 'Color', colors(c_idx, :));
end
xlabel('Chirp Excitation Frequency (Hz)');
ylabel('Phase Angle (degrees)');
title('THISULINK Mechanical Phase Response (Acceleration vs Force)');
legend(class_names, 'Location', 'southwest');
grid on;
saveas(gcf, fullfile(resultsFolder, 'phase_response.png'));
