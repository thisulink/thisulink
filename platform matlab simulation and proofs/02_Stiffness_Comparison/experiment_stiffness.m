%% THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM
% Experiment 2: Plantar Tissue Stiffness Comparison
% Healthy Compliant vs Early Glycation vs Severe Diabetic Neuropathy
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

%% Define The Three Diagnostic Clinical Classes
k_values  = [k_A,  k_B,  k_C];     % [800, 1500, 2600] N/m
c_values  = [c_A,  c_B,  c_C];     % [2.50, 3.20, 4.50] N*s/m
mu_values = [mu_A, mu_B, mu_C];    % [14.5, 32.0, 68.0] kPa
E_values  = [E_A,  E_B,  E_C];     % [43.5, 96.0, 204.0] kPa
cs_values = [cs_A, cs_B, cs_C];    % [3.72, 5.52, 8.05] m/s

class_names = {
    'Class 1: Healthy Control (Compliant)'
    'Class 2: Early Glycation (Moderate Stiffening)'
    'Class 3: Diabetic Neuropathy (High Ulcer Risk)'
};

numClasses = 3;
N_pts = length(t);

displacement_all = zeros(N_pts, numClasses);
velocity_all     = zeros(N_pts, numClasses);
acceleration_all = zeros(N_pts, numClasses);
peak_acc         = zeros(numClasses, 1);
rms_acc          = zeros(numClasses, 1);
peak_disp        = zeros(numClasses, 1);

%% Initial State
x0 = [0; 0];
force = F0 * sin(2 * pi * f_exc * t);

%% Simulate All 3 Biomechanical Classes
for i = 1:numClasses
    k_curr = k_values(i);
    c_curr = c_values(i);
    
    [~, X] = ode45(@(tt, x) tissue_model(tt, x, m, c_curr, k_curr, F0, f_exc), t, x0);
    
    disp_curr = X(:, 1);
    vel_curr  = X(:, 2);
    acc_curr  = (force - c_curr * vel_curr - k_curr * disp_curr) / m;
    
    displacement_all(:, i) = disp_curr;
    velocity_all(:, i)     = vel_curr;
    acceleration_all(:, i) = acc_curr;
    
    peak_disp(i) = max(abs(disp_curr));
    peak_acc(i)  = max(abs(acc_curr));
    rms_acc(i)   = rms(acc_curr);
end

%% Theoretical Resonance Frequencies
fn = (1 / (2 * pi)) .* sqrt(k_values ./ m);

%% Console Output
fprintf('\n========================================================================\n');
fprintf('  THISULINK EXPERIMENT 02: PLANTAR TISSUE STIFFNESS COMPARISON         \n');
fprintf('========================================================================\n');
for i = 1:numClasses
    fprintf('\n%s:\n', class_names{i});
    fprintf('  Stiffness (k)           : %.1f N/m\n', k_values(i));
    fprintf('  Shear Modulus (mu)      : %.1f kPa\n', mu_values(i)/1000);
    fprintf('  Young Modulus (E)       : %.1f kPa\n', E_values(i)/1000);
    fprintf('  Shear Wave Speed (cs)   : %.2f m/s\n', cs_values(i));
    fprintf('  Natural Frequency (fn)  : %.2f Hz\n', fn(i));
    fprintf('  Peak Displacement       : %.4f mm\n', peak_disp(i)*1000);
    fprintf('  Peak Acceleration       : %.4f m/s^2\n', peak_acc(i));
    fprintf('  RMS Acceleration        : %.4f m/s^2\n', rms_acc(i));
end
fprintf('========================================================================\n\n');

%% Results Directory
resultsFolder = fullfile(expDir, 'results');
if ~exist(resultsFolder, 'dir')
    mkdir(resultsFolder);
end

colors = [0.0 0.45 0.74; 0.85 0.33 0.10; 0.64 0.08 0.18];

%% Plot 1: Displacement Comparison
figure('Name', 'THISULINK - Displacement Comparison', 'Color', 'w');
hold on;
for i = 1:numClasses
    plot(t(1:400) * 1000, displacement_all(1:400, i) * 1000, 'LineWidth', 1.8, 'Color', colors(i,:));
end
xlabel('Time (ms)');
ylabel('Displacement (mm)');
title('THISULINK Plantar Dynamic Displacement Across Diagnostic Classes');
legend(class_names, 'Location', 'best');
grid on;
saveas(gcf, fullfile(resultsFolder, 'stiffness_displacement.png'));

%% Plot 2: Acceleration Comparison
figure('Name', 'THISULINK - Acceleration Comparison', 'Color', 'w');
hold on;
for i = 1:numClasses
    plot(t(1:400) * 1000, acceleration_all(1:400, i), 'LineWidth', 1.8, 'Color', colors(i,:));
end
xlabel('Time (ms)');
ylabel('Acceleration (m/s^2)');
title('THISULINK Plantar Dynamic Acceleration Across Diagnostic Classes');
legend(class_names, 'Location', 'best');
grid on;
saveas(gcf, fullfile(resultsFolder, 'stiffness_acceleration.png'));

%% Plot 3: Natural Frequency Resonance Shift
figure('Name', 'THISULINK - Resonance Shift', 'Color', 'w');
b1 = bar(fn, 0.55);
b1.FaceColor = 'flat';
b1.CData(1,:) = colors(1,:);
b1.CData(2,:) = colors(2,:);
b1.CData(3,:) = colors(3,:);
set(gca, 'XTick', 1:3, 'XTickLabel', {'Healthy', 'Early Glycated', 'Diabetic Neuropathy'});
ylabel('Natural Frequency f_n (Hz)');
title('THISULINK Plantar Tissue Resonance Shift Under Glycation');
grid on;
for i = 1:3
    text(i, fn(i) + 1.2, sprintf('%.1f Hz', fn(i)), 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end
saveas(gcf, fullfile(resultsFolder, 'natural_frequency_comparison.png'));

%% Plot 4: Shear Wave Speed & Modulus Comparison
figure('Name', 'THISULINK - Shear Speed and Elasticity', 'Color', 'w');
subplot(1, 2, 1);
b_cs = bar(cs_values, 0.5);
b_cs.FaceColor = 'flat';
b_cs.CData(1,:) = colors(1,:); b_cs.CData(2,:) = colors(2,:); b_cs.CData(3,:) = colors(3,:);
set(gca, 'XTick', 1:3, 'XTickLabel', {'Healthy', 'Early', 'Neuropathic'});
ylabel('Shear Wave Speed c_s (m/s)');
title('Shear Wave Speed (m/s)');
grid on;
for i = 1:3
    text(i, cs_values(i) + 0.3, sprintf('%.2f m/s', cs_values(i)), 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

subplot(1, 2, 2);
b_E = bar(E_values / 1000, 0.5);
b_E.FaceColor = 'flat';
b_E.CData(1,:) = colors(1,:); b_E.CData(2,:) = colors(2,:); b_E.CData(3,:) = colors(3,:);
set(gca, 'XTick', 1:3, 'XTickLabel', {'Healthy', 'Early', 'Neuropathic'});
ylabel('Young Modulus E (kPa)');
title('Plantar Elastic Modulus (kPa)');
grid on;
for i = 1:3
    text(i, (E_values(i)/1000) + 7, sprintf('%.1f kPa', E_values(i)/1000), 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end
saveas(gcf, fullfile(resultsFolder, 'shear_speed_modulus_comparison.png'));
