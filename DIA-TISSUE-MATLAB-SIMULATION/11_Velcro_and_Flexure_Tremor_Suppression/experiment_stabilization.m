%% THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM
% Experiment 11: Velcro Stabilization Strap & Planar Flexure Tremor Suppression Proof
% Direct Mathematical Proof for THISULINK CAD Mechanical Upgrades
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

%% Foot Tremor & Platform Mechanical Specifications
m_foot = 1.20;            % Effective foot segment mass [kg]
k_foot_free = 500.0;      % Ankle/subtalar joint passive unconstrained stiffness [N/m]
c_foot_free = 10.0;       % Soft-tissue passive damping [N*s/m]

% THISULINK Mechanical Stabilization Hardware
k_strap = k_velcro_strap; % 12,000 N/m (Medical-grade Velcro instep/heel restraint)
c_strap = c_velcro_strap; % 35 N*s/m (Velcro composite friction damping)
k_flex  = k_flexure_lat;  % 7,500 N/m (Planar beryllium copper flexure lateral clamp)

% Combined Constrained Platform Stiffness and Damping
k_constrained = k_foot_free + k_strap + k_flex; % ~20,000 N/m
c_constrained = c_foot_free + c_strap;          % ~45 N*s/m

%% Tremor Excitation Signal (Involuntary Parkinsonian / Diabetic Neuropathic Tremor)
f_tremor1 = 3.2; % Hz
f_tremor2 = 4.5; % Hz
f_tremor3 = 2.1; % Hz
F_tremor_amp = 1.80; % N

t_tremor = (0:1/fs:2.5-1/fs)';
F_tremor = F_tremor_amp * (0.65 * sin(2*pi*f_tremor1*t_tremor) + ...
                           0.25 * sin(2*pi*f_tremor2*t_tremor + 0.4) + ...
                           0.10 * sin(2*pi*f_tremor3*t_tremor - 0.7));

%% Simulate Motions
x0 = [0; 0];
ode_free = @(tt, x) [x(2); (interp1(t_tremor, F_tremor, tt) - c_foot_free*x(2) - k_foot_free*x(1)) / m_foot];
[~, X_free] = ode45(ode_free, t_tremor, x0);
disp_free = X_free(:, 1);

ode_clamped = @(tt, x) [x(2); (interp1(t_tremor, F_tremor, tt) - c_constrained*x(2) - k_constrained*x(1)) / m_foot];
[~, X_clamped] = ode45(ode_clamped, t_tremor, x0);
disp_clamped = X_clamped(:, 1);

peak_disp_free    = max(abs(disp_free));
peak_disp_clamped = max(abs(disp_clamped));
attenuation_pct   = (1 - peak_disp_clamped / peak_disp_free) * 100;

fprintf('\n========================================================================\n');
fprintf('  THISULINK EXPERIMENT 11: VELCRO STRAP & FLEXURE STABILIZATION PROOF    \n');
fprintf('========================================================================\n');
fprintf('Unconstrained Tremor Peak     : %.4f mm (%.1f um)\n', peak_disp_free*1000, peak_disp_free*1e6);
fprintf('THISULINK Clamped Tremor Peak : %.4f mm (%.1f um)\n', peak_disp_clamped*1000, peak_disp_clamped*1e6);
fprintf('Tremor Motion Attenuation     : %.2f%%\n', attenuation_pct);
fprintf('========================================================================\n\n');

resultsFolder = fullfile(expDir, 'results');
if ~exist(resultsFolder, 'dir')
    mkdir(resultsFolder);
end
