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
% Simulating real-world ASHA frontline screening demographic distribution:
%   Group 1: Healthy Controls (N = 40)
%   Group 2: Early Subclinical Glycation (N = 35)
%   Group 3: Advanced Diabetic Neuropathy (N = 30)
%   Group 4: Acute Charcot Neuroarthropathy / Active Flare (N = 15)

rng(2026);
N1 = 40; N2 = 35; N3 = 30; N4 = 15;
N_total = N1 + N2 + N3 + N4;

% Elasticity E [kPa]
E_grp1 = 42.0 + 8.0 .* randn(N1, 1);   % Healthy (mean = 42 kPa)
E_grp2 = 88.0 + 12.0 .* randn(N2, 1);  % Early Glycation (mean = 88 kPa)
E_grp3 = 175.0 + 25.0 .* randn(N3, 1); % Advanced Neuropathy (mean = 175 kPa)
E_grp4 = 145.0 + 30.0 .* randn(N4, 1); % Charcot / Inflamed (mean = 145 kPa)

E_cohort = max(15.0, [E_grp1; E_grp2; E_grp3; E_grp4]);

% Contralateral Temperature Differential Delta T [deg C] (MLX90621 16x4 FIR Array)
dT_grp1 = abs(0.40 + 0.25 .* randn(N1, 1));  % Healthy (mean = 0.4 C)
dT_grp2 = abs(0.75 + 0.35 .* randn(N2, 1));  % Early (mean = 0.75 C)
dT_grp3 = abs(1.20 + 0.40 .* randn(N3, 1));  % Neuropathy (mean = 1.2 C)
dT_grp4 = 2.65 + 0.50 .* abs(randn(N4, 1));  % Charcot Active Flare (mean = 2.65 C >= 2.2 C)

dT_cohort = [dT_grp1; dT_grp2; dT_grp3; dT_grp4];

% Ground Truth Labels (0: Healthy, 1: Early, 2: High Ulcer Risk, 3: Acute Charcot)
ground_truth = [zeros(N1, 1); ones(N2, 1); 2*ones(N3, 1); 3*ones(N4, 1)];

%% THISULINK Automated Multimodal Triage Decision Engine
triage_grade = zeros(N_total, 1);
triage_action = strings(N_total, 1);

% Clinical Thresholds:
E_thresh_moderate = 65.0;  % kPa
E_thresh_high     = 120.0; % kPa
dT_charcot_thresh = 2.20;  % deg C (Armstrong & Lavery contralateral threshold)

for i = 1:N_total
    E_val  = E_cohort(i);
    dT_val = dT_cohort(i);
    
    if dT_val >= dT_charcot_thresh
        % Emergency Priority Tier: Acute Inflammatory Flare / Charcot Warning
        triage_grade(i) = 3;
        triage_action(i) = "RED: Acute Charcot / Active Inflammatory Flare (Immediate Immobilization)";
    elseif E_val >= E_thresh_high
        % High Mechanical Ulcer Risk Tier
        triage_grade(i) = 2;
        triage_action(i) = "ORANGE: Advanced Neuropathic Stiffening (Specialist Podiatry Referral)";
    elseif E_val >= E_thresh_moderate
        % Subclinical Early Glycation Tier
        triage_grade(i) = 1;
        triage_action(i) = "YELLOW: Subclinical Loss of Compliance (Custom Offloading Insole)";
    else
        % Normal Tier
        triage_grade(i) = 0;
        triage_action(i) = "GREEN: Low Risk (Annual ASHA Follow-Up)";
    end
end

%% Classification Performance Metrics
correct_classifications = sum(triage_grade == ground_truth);
accuracy_pct = (correct_classifications / N_total) * 100;

% Charcot detection sensitivity & specificity
charcot_true = (ground_truth == 3);
charcot_pred = (triage_grade == 3);
charcot_sens = sum(charcot_true & charcot_pred) / sum(charcot_true) * 100;
charcot_spec = sum(~charcot_true & ~charcot_pred) / sum(~charcot_true) * 100;

% Stiffening detection sensitivity (Early + Advanced)
stiff_true = (ground_truth >= 1);
stiff_pred = (triage_grade >= 1);
stiff_sens = sum(stiff_true & stiff_pred) / sum(stiff_true) * 100;
stiff_spec = sum(~stiff_true & ~stiff_pred) / sum(~stiff_true) * 100;

%% Console Output
fprintf('\n========================================================================\n');
fprintf('  THISULINK EXPERIMENT 12: DUAL-MODALITY FRONTLINE TRIAGE INTEGRATION    \n');
fprintf('========================================================================\n');
fprintf('Total Patient Cohort Evaluated: N = %d\n', N_total);
fprintf('  Class 0 (Healthy Controls)  : %d patients\n', N1);
fprintf('  Class 1 (Early Glycation)   : %d patients\n', N2);
fprintf('  Class 2 (Diabetic Neuropathy): %d patients\n', N3);
fprintf('  Class 3 (Charcot Flare)     : %d patients\n', N4);
fprintf('------------------------------------------------------------------------\n');
fprintf('Clinical Thresholds Applied:\n');
fprintf('  Moderate Stiffness Boundary : E >= %.1f kPa\n', E_thresh_moderate);
fprintf('  Severe Stiffness Boundary   : E >= %.1f kPa\n', E_thresh_high);
fprintf('  Charcot Hyperemia Boundary  : Delta T >= %.2f deg C (Contralateral Asymmetry)\n', ...
    dT_charcot_thresh);
fprintf('------------------------------------------------------------------------\n');
fprintf('TRIAGE CLASSIFICATION RESULTS:\n');
fprintf('  Overall Diagnostic Accuracy : %.2f%%\n', accuracy_pct);
fprintf('  Charcot Flare Sensitivity   : %.2f%%\n', charcot_sens);
fprintf('  Charcot Flare Specificity   : %.2f%%\n', charcot_spec);
fprintf('  Tissue Stiffening Sens      : %.2f%%\n', stiff_sens);
fprintf('  Tissue Stiffening Spec      : %.2f%%\n', stiff_spec);
fprintf('========================================================================\n\n');

%% Results Directory
resultsFolder = fullfile(expDir, 'results');
if ~exist(resultsFolder, 'dir')
    mkdir(resultsFolder);
end

%% Plot 1: 2D Multimodal Diagnostic Triage Space
figure('Name', 'THISULINK - Multimodal Triage Space', 'Color', 'w');
hold on;

% Decision regions
fill([0 65 65 0], [0 0 2.2 2.2], [0.85 1.0 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.4); % Green
fill([65 120 120 65], [0 0 2.2 2.2], [1.0 1.0 0.80], 'EdgeColor', 'none', 'FaceAlpha', 0.4); % Yellow
fill([120 250 250 120], [0 0 2.2 2.2], [1.0 0.88 0.80], 'EdgeColor', 'none', 'FaceAlpha', 0.4); % Orange
fill([0 250 250 0], [2.2 2.2 4.0 4.0], [1.0 0.80 0.80], 'EdgeColor', 'none', 'FaceAlpha', 0.4); % Red

% Plot patients
p0 = plot(E_cohort(ground_truth==0), dT_cohort(ground_truth==0), 'o', 'MarkerFaceColor', [0 0.6 0], ...
    'MarkerEdgeColor', 'k', 'MarkerSize', 8);
p1 = plot(E_cohort(ground_truth==1), dT_cohort(ground_truth==1), '^', 'MarkerFaceColor', [0.9 0.7 0], ...
    'MarkerEdgeColor', 'k', 'MarkerSize', 8);
p2 = plot(E_cohort(ground_truth==2), dT_cohort(ground_truth==2), 's', 'MarkerFaceColor', [0.85 0.33 0.1], ...
    'MarkerEdgeColor', 'k', 'MarkerSize', 8);
p3 = plot(E_cohort(ground_truth==3), dT_cohort(ground_truth==3), 'p', 'MarkerFaceColor', 'r', ...
    'MarkerEdgeColor', 'k', 'MarkerSize', 12);

% Threshold lines
xline(E_thresh_moderate, '--k', 'E = 65 kPa', 'LineWidth', 1.2);
xline(E_thresh_high, '--k', 'E = 120 kPa', 'LineWidth', 1.2);
yline(dT_charcot_thresh, '--r', '\DeltaT = 2.2^\circC (Charcot Threshold)', 'LineWidth', 1.5);

xlim([15, 240]);
ylim([0, 3.8]);
xlabel('Plantar SWE Young Modulus E (kPa)');
ylabel('Contralateral FIR Thermal Differential \DeltaT (^\circC)');
title('THISULINK Dual-Modality Frontline Triage Map (N = 120 Cohort)');
legend([p0, p1, p2, p3], {'Grade 0: Healthy Control', 'Grade 1: Early Glycation', ...
    'Grade 2: Neuropathic Stiffening', 'Grade 3: Acute Charcot Flare'}, 'Location', 'northeast');
grid on;
saveas(gcf, fullfile(resultsFolder, 'multimodal_triage_scatter.png'));

%% Plot 2: Triage Distribution Confusion Matrix
figure('Name', 'THISULINK - Confusion Matrix', 'Color', 'w');
conf_mat = confusionmat(ground_truth, triage_grade);
imagesc(conf_mat);
colormap(flipud(gray));
colorbar;
set(gca, 'XTick', 1:4, 'XTickLabel', {'Grade 0', 'Grade 1', 'Grade 2', 'Grade 3'});
set(gca, 'YTick', 1:4, 'YTickLabel', {'Grade 0', 'Grade 1', 'Grade 2', 'Grade 3'});
xlabel('THISULINK Predicted Triage Grade');
ylabel('True Clinical Diagnosis');
title(sprintf('THISULINK Triage Classification Matrix (Accuracy = %.1f%%)', accuracy_pct));

for r = 1:4
    for c = 1:4
        text(c, r, num2str(conf_mat(r, c)), 'HorizontalAlignment', 'center', ...
            'FontWeight', 'bold', 'FontSize', 12, 'Color', ...
            conf_mat(r,c) > max(conf_mat(:))/2 ? [1 1 1] : [0 0 0]);
    end
end
saveas(gcf, fullfile(resultsFolder, 'triage_confusion_matrix.png'));
