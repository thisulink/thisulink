%% THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM
% Experiment 12: Dual-Modality Frontline Triage Integration
% Plantar SWE Elasticity (E) + MLX90621 Differential FIR Thermometry (Delta T)
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

%% Generate Synthetic Frontline Patient Cohort (N = 120 Patients)
rng(2026);
N1 = 40; N2 = 35; N3 = 30; N4 = 15;
N_total = N1 + N2 + N3 + N4;

E_grp1 = 42.0 + 8.0 .* randn(N1, 1);
E_grp2 = 88.0 + 12.0 .* randn(N2, 1);
E_grp3 = 175.0 + 25.0 .* randn(N3, 1);
E_grp4 = 145.0 + 30.0 .* randn(N4, 1);
E_cohort = max(15.0, [E_grp1; E_grp2; E_grp3; E_grp4]);

dT_grp1 = abs(0.40 + 0.25 .* randn(N1, 1));
dT_grp2 = abs(0.75 + 0.35 .* randn(N2, 1));
dT_grp3 = abs(1.20 + 0.40 .* randn(N3, 1));
dT_grp4 = 2.65 + 0.50 .* abs(randn(N4, 1));
dT_cohort = [dT_grp1; dT_grp2; dT_grp3; dT_grp4];

ground_truth = [zeros(N1, 1); ones(N2, 1); 2*ones(N3, 1); 3*ones(N4, 1)];

%% THISULINK Triage Decision Engine
triage_grade = zeros(N_total, 1);
E_thresh_moderate = 65.0;
E_thresh_high     = 120.0;
dT_charcot_thresh = 2.20;

for i = 1:N_total
    E_val  = E_cohort(i);
    dT_val = dT_cohort(i);
    
    if dT_val >= dT_charcot_thresh
        triage_grade(i) = 3;
    elseif E_val >= E_thresh_high
        triage_grade(i) = 2;
    elseif E_val >= E_thresh_moderate
        triage_grade(i) = 1;
    else
        triage_grade(i) = 0;
    end
end

correct_classifications = sum(triage_grade == ground_truth);
accuracy_pct = (correct_classifications / N_total) * 100;

fprintf('\n========================================================================\n');
fprintf('  THISULINK EXPERIMENT 12: DUAL-MODALITY FRONTLINE TRIAGE INTEGRATION    \n');
fprintf('========================================================================\n');
fprintf('Total Cohort Size             : N = %d\n', N_total);
fprintf('Overall Diagnostic Accuracy   : %.2f%%\n', accuracy_pct);
fprintf('========================================================================\n\n');

resultsFolder = fullfile(expDir, 'results');
if ~exist(resultsFolder, 'dir')
    mkdir(resultsFolder);
end
