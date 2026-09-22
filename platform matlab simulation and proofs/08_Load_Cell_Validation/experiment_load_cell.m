%% THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM
% Experiment 8: Micro Load-Cell Contact Validation & Safety Interlock Logic
% Hardware: HX711 24-Bit ADC + Precision Miniature Beam Load Cell
% Interlock Window: 1.50 N +/- 0.10 N (1.40 N - 1.60 N)
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

%% Load Cell Interlock Specifications
F_target = F_preload_target;  % 1.50 N
F_min    = F_preload_min;     % 1.40 N
F_max    = F_preload_max;     % 1.60 N
sigma_F  = load_cell_noise;   % 0.015 N (HX711 24-bit RMS noise)

%% Test Trial Conditions (Simulating real frontline clinical encounters)
trial_names = {
    'Trial 1: Foot Barely Resting (Insufficient Contact)'
    'Trial 2: Slanted Heel Footfall (Loose Margin)'
    'Trial 3: Nominal Foot Placement (Calibrated Target)'
    'Trial 4: Upper Nominal Bound'
    'Trial 5: Moderate Involuntary Muscle Push'
    'Trial 6: Full Heavy Foot Leaning (Excessive Overload)'
};

true_preloads = [0.85; 1.32; 1.51; 1.58; 1.85; 3.20]; % [N]
numTrials = length(true_preloads);

%% Simulate 24-Bit Load Cell Measurements (100 samples per trial at 80 Hz)
rng(2026);
samples_per_trial = 100;
t_trial = (0:samples_per_trial-1)' / 80; % 80 Hz load cell sampling rate

measured_trials = zeros(samples_per_trial, numTrials);
mean_measured   = zeros(numTrials, 1);
std_measured    = zeros(numTrials, 1);
interlock_state = strings(numTrials, 1);
wave_launch_ok  = false(numTrials, 1);

for i = 1:numTrials
    noise_vec = sigma_F .* randn(samples_per_trial, 1);
    measured_trials(:, i) = true_preloads(i) + noise_vec;
    
    mean_val = mean(measured_trials(:, i));
    mean_measured(i) = mean_val;
    std_measured(i)  = std(measured_trials(:, i));
    
    % THISULINK Hardware Preload State Machine
    if mean_val < F_min
        interlock_state(i) = "LOCKOUT: INSUFFICIENT PRELOAD (< 1.40 N)";
        wave_launch_ok(i)  = false;
    elseif mean_val > F_max
        interlock_state(i) = "LOCKOUT: EXCESSIVE TISSUE PRE-COMPRESSION (> 1.60 N)";
        wave_launch_ok(i)  = false;
    else
        interlock_state(i) = "INTERLOCK CLEARED: 1.50 N NOMINAL PRELOAD VALIDATED";
        wave_launch_ok(i)  = true;
    end
end

%% Console Output
fprintf('\n========================================================================\n');
fprintf('  THISULINK EXPERIMENT 08: MICRO LOAD-CELL CONTACT INTERLOCK VALIDATION \n');
fprintf('========================================================================\n');
fprintf('Target Calibrated Preload     : %.2f N\n', F_target);
fprintf('Acceptable Interlock Window   : %.2f N - %.2f N (1.50 N +/- 0.10 N)\n', F_min, F_max);
fprintf('Load Cell Noise Floor (RMS)   : %.4f N (HX711 24-bit ADC)\n', sigma_F);
fprintf('------------------------------------------------------------------------\n');
fprintf('Trial\tTrue(N)\tMean Meas(N)\tStd(N)\tInterlock Decision\n');
fprintf('------------------------------------------------------------------------\n');
for i = 1:numTrials
    fprintf('%d\t%.2f\t%.3f\t\t%.4f\t%s\n', ...
        i, true_preloads(i), mean_measured(i), std_measured(i), interlock_state(i));
end
fprintf('========================================================================\n\n');

%% Results Directory
resultsFolder = fullfile(expDir, 'results');
if ~exist(resultsFolder, 'dir')
    mkdir(resultsFolder);
end

%% Plot 1: True vs Measured Preload Bar Chart
figure('Name', 'THISULINK - Load Cell Validation', 'Color', 'w');
b = bar([true_preloads, mean_measured]);
b(1).FaceColor = [0.0 0.45 0.74];
b(2).FaceColor = [0.85 0.33 0.10];
xlabel('Clinical Test Encounter');
ylabel('Contact Preload Force (N)');
title('THISULINK Micro Load-Cell True vs Measured Preload Force');
set(gca, 'XTick', 1:numTrials, 'XTickLabel', {'Trial 1', 'Trial 2', 'Trial 3', 'Trial 4', 'Trial 5', 'Trial 6'});
legend('True Physical Force', 'HX711 24-Bit Measured Mean', 'Location', 'northwest');
grid on;
saveas(gcf, fullfile(resultsFolder, 'load_cell_true_vs_measured.png'));

%% Plot 2: Interlock Gate Boundary Verification
figure('Name', 'THISULINK - Interlock Gate Boundaries', 'Color', 'w');
hold on;
fill([0, numTrials+1, numTrials+1, 0], [F_min, F_min, F_max, F_max], ...
     [0.85 1.0 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.6);
plot(1:numTrials, mean_measured, 'o-k', 'LineWidth', 1.8, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
yline(F_target, '-g', 'Calibrated Target Preload (1.50 N)', 'LineWidth', 1.5);
yline(F_min, '--r', 'Minimum Wave Launch Threshold (1.40 N)', 'LineWidth', 1.3);
yline(F_max, '--r', 'Maximum Wave Launch Threshold (1.60 N)', 'LineWidth', 1.3);

for i = 1:numTrials
    if wave_launch_ok(i)
        plot(i, mean_measured(i), 'p', 'MarkerSize', 14, 'MarkerFaceColor', [0.47 0.67 0.19], 'MarkerEdgeColor', 'k');
        text(i, mean_measured(i) + 0.12, 'WAVE LAUNCH OK', 'HorizontalAlignment', 'center', ...
            'FontWeight', 'bold', 'Color', [0 0.5 0], 'FontSize', 9);
    else
        plot(i, mean_measured(i), 'x', 'MarkerSize', 12, 'LineWidth', 2.5, 'Color', 'r');
        text(i, mean_measured(i) + 0.15, 'INTERLOCK LOCKED', 'HorizontalAlignment', 'center', ...
            'FontWeight', 'bold', 'Color', 'r', 'FontSize', 9);
    end
end

xlim([0.5, numTrials + 0.5]);
ylim([0.5, 3.6]);
xlabel('Clinical Patient Encounter');
ylabel('Measured Contact Preload Force (N)');
title('THISULINK Automated Contact Interlock State Machine Gate');
legend('Safe Preload Window (1.40 - 1.60 N)', 'Measured Preload', 'Location', 'northeast');
grid on;
saveas(gcf, fullfile(resultsFolder, 'load_cell_validation_limits.png'));
