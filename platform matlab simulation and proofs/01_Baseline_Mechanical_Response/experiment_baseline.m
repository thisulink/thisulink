%% THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM
% Experiment 1: Baseline Mechanical Response Under Calibrated Preload
% Subsystem: Voice Coil Actuator (VCA) + Plantar Heel Pad Contact
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

%% Selected Model: Class 1 - Healthy Compliant Control
m_model = m;          % 0.0450 kg
k_model = k_A;        % 800 N/m
c_model = c_A;        % 2.50 N*s/m
mu_model = mu_A;      % 14.5 kPa
cs_model = cs_A;      % 3.72 m/s

%% Initial State [displacement; velocity]
x0 = [0; 0];

%% ODE45 Simulation of Dynamic Plantar Response
[t_sim, X] = ode45(@(tt, x) tissue_model(tt, x, m_model, c_model, k_model, F0, f_exc), t, x0);

displacement = X(:, 1);
velocity = X(:, 2);

% Applied dynamic excitation force (F0 = 0.100 N at f_exc = 50 Hz)
force = F0 * sin(2 * pi * f_exc * t_sim);

% Acceleration computation
acceleration = (force - c_model * velocity - k_model * displacement) / m_model;

%% Metrics Extraction
peak_displacement = max(abs(displacement));
rms_displacement = rms(displacement);
peak_velocity = max(abs(velocity));
rms_velocity = rms(velocity);
peak_acceleration = max(abs(acceleration));
rms_acceleration = rms(acceleration);

%% Static Preload Indentation (Hayes Elastic Layer Model)
% Delta_z_static = F_preload / k_model
delta_z_static = F_preload_target / k_model;

%% Console Output
fprintf('\n========================================================================\n');
fprintf('  THISULINK EXPERIMENT 01: BASELINE MECHANICAL RESPONSE                 \n');
fprintf('========================================================================\n');
fprintf('Tissue Model              : Class 1 (Healthy Compliant Control)\n');
fprintf('Moving Mass (m)           : %.4f kg\n', m_model);
fprintf('Tissue Stiffness (k)      : %.2f N/m\n', k_model);
fprintf('Damping Coefficient (c)   : %.2f N*s/m\n', c_model);
fprintf('Diagnostic Frequency (f)  : %.2f Hz\n', f_exc);
fprintf('Dynamic Force (F0)        : %.3f N (100 mN)\n', F0);
fprintf('Static Preload (F_pre)    : %.2f N\n', F_preload_target);
fprintf('Static Indentation        : %.3f mm\n', delta_z_static * 1000);
fprintf('------------------------------------------------------------------------\n');
fprintf('Peak Dynamic Displacement : %.4f mm (%.4e m)\n', peak_displacement * 1000, peak_displacement);
fprintf('RMS Dynamic Displacement  : %.4f mm (%.4e m)\n', rms_displacement * 1000, rms_displacement);
fprintf('Peak Surface Velocity     : %.4f mm/s (%.4e m/s)\n', peak_velocity * 1000, peak_velocity);
fprintf('RMS Surface Velocity      : %.4f mm/s (%.4e m/s)\n', rms_velocity * 1000, rms_velocity);
fprintf('Peak Dynamic Acceleration : %.4f m/s^2 (%.3f g)\n', peak_acceleration, peak_acceleration / 9.80665);
fprintf('RMS Dynamic Acceleration  : %.4f m/s^2 (%.3f g)\n', rms_acceleration, rms_acceleration / 9.80665);
fprintf('Theoretical Shear Speed   : %.2f m/s\n', cs_model);
fprintf('========================================================================\n\n');

%% Results Directory
resultsFolder = fullfile(expDir, 'results');
if ~exist(resultsFolder, 'dir')
    mkdir(resultsFolder);
end

%% Plotting
% Figure 1: Dynamic Force
figure('Name', 'THISULINK - Dynamic Excitation Force', 'Color', 'w');
plot(t_sim, force, 'Color', [0.0 0.45 0.74], 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Dynamic Force (N)');
title('THISULINK Plantar Excitation Force (100 mN @ 50 Hz)');
grid on;
saveas(gcf, fullfile(resultsFolder, 'baseline_force.png'));

% Figure 2: Dynamic Displacement
figure('Name', 'THISULINK - Plantar Dynamic Displacement', 'Color', 'w');
plot(t_sim * 1000, displacement * 1000, 'Color', [0.85 0.33 0.1], 'LineWidth', 1.5);
xlabel('Time (ms)');
ylabel('Dynamic Displacement (mm)');
title(sprintf('THISULINK Plantar Dynamic Displacement (Peak = %.3f mm)', peak_displacement*1000));
grid on;
saveas(gcf, fullfile(resultsFolder, 'baseline_displacement.png'));

% Figure 3: Dynamic Velocity
figure('Name', 'THISULINK - Plantar Surface Velocity', 'Color', 'w');
plot(t_sim * 1000, velocity * 1000, 'Color', [0.93 0.69 0.13], 'LineWidth', 1.5);
xlabel('Time (ms)');
ylabel('Surface Velocity (mm/s)');
title('THISULINK Plantar Surface Velocity');
grid on;
saveas(gcf, fullfile(resultsFolder, 'baseline_velocity.png'));

% Figure 4: Dynamic Acceleration
figure('Name', 'THISULINK - Plantar Surface Acceleration', 'Color', 'w');
plot(t_sim * 1000, acceleration, 'Color', [0.47 0.67 0.19], 'LineWidth', 1.5);
xlabel('Time (ms)');
ylabel('Acceleration (m/s^2)');
title(sprintf('THISULINK Plantar Surface Acceleration (Peak = %.3f m/s^2)', peak_acceleration));
grid on;
saveas(gcf, fullfile(resultsFolder, 'baseline_acceleration.png'));
