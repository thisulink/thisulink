%% THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM
% Experiment 12: Dual-Modality Frontline Triage Integration (SIMULATION)
% Plantar SWE Elasticity (E) + MLX90621 Differential FIR Thermometry (Delta T)
%
% What this script does:
%   1. Draws a SYNTHETIC cohort of N = 120 virtual patients (4 groups) with an
%      assumed "true" plantar modulus E and contralateral temperature
%      difference Delta T. The group means/spreads are modelling
%      assumptions, not patient data.
%   2. "Measures" each patient's E with the simulated device: Kelvin-Voigt
%      propagation to the two pickups (common/shear_wave_propagation_model.m),
%      ADXL355 digitisation (05_Sensor_Simulation/sensor_model.m), 50 Hz
%      phase difference -> c -> E = 3*rho*c^2. Contact preload varies inside
%      the 1.40-1.60 N interlock window (stiffening model of Experiment 07).
%      Delta T gets MLX90621-like noise (NETD 0.1 degC per side).
%   3. Applies the triage table in README.md and prints accuracy,
%      sensitivity, specificity and the confusion matrix.
%
% The metrics describe how well the decision rules separate the synthetic
% groups that were generated for them. They are NOT clinical accuracy.
% All random numbers come from common/det_randn.m, so MATLAB and Octave
% print identical results.

% (No clear/clc/close all here: the master runner executes every experiment
%  in its own workspace, and clearing would break callers.)

%% Path Setup
expDir = fileparts(mfilename('fullpath'));
if isempty(expDir), expDir = pwd; end
projectRoot = fileparts(expDir);
addpath(fullfile(projectRoot, 'common'));
addpath(fullfile(projectRoot, '05_Sensor_Simulation'));

%% Load Calibrated Parameters
simulation_parameters;

%% 1. Synthetic cohort (N = 120)
%   Group 0: Healthy Controls                        (N = 40)
%   Group 1: Early Subclinical Glycation             (N = 35)
%   Group 2: Advanced Diabetic Neuropathy            (N = 30)
%   Group 3: Acute Charcot Neuroarthropathy / Flare  (N = 15)
N1 = 40; N2 = 35; N3 = 30; N4 = 15;
N_total = N1 + N2 + N3 + N4;

% "True" Young's modulus E [kPa] (assumed group distributions)
E_true = [42.0  +  8.0 .* det_randn(1201, N1);
          88.0  + 12.0 .* det_randn(1202, N2);
          175.0 + 25.0 .* det_randn(1203, N3);
          145.0 + 30.0 .* det_randn(1204, N4)];
E_true = max(15.0, E_true);

% "True" contralateral temperature difference Delta T [degC] (assumed)
dT_true = [abs(0.40 + 0.25 .* det_randn(1211, N1));
           abs(0.75 + 0.35 .* det_randn(1212, N2));
           abs(1.20 + 0.40 .* det_randn(1213, N3));
           2.65 + 0.50 .* abs(det_randn(1214, N4))];

% Ground-truth labels (0: Healthy, 1: Early, 2: High ulcer risk, 3: Acute Charcot)
ground_truth = [zeros(N1, 1); ones(N2, 1); 2*ones(N3, 1); 3*ones(N4, 1)];

%% 2. Simulated device measurement of every patient
sensor_params.range_g       = sensor_range_g;
sensor_params.bits          = sensor_bits;
sensor_params.bandwidth     = sensor_bandwidth;
sensor_params.noise_density = sensor_noise_dens;
sensor_params.bias          = sensor_bias;

mu_cls  = [mu_A,  mu_B,  mu_C];
eta_cls = [eta_A, eta_B, eta_C];
k_cls   = [k_A,   k_B,   k_C];
c_cls   = [c_A,   c_B,   c_C];

w0 = 2 * pi * f_exc;
preload = min(F_preload_max, max(F_preload_min, F_preload_target + 0.04 .* det_randn(1221, N_total)));
dT_noise_sd = 0.10 * sqrt(2);             % NETD 0.1 degC on each foot -> difference
dT_meas = dT_true + dT_noise_sd .* det_randn(1222, N_total);

E_meas = zeros(N_total, 1);
for p = 1:N_total
    mu_p  = E_true(p) * 1000 / 3;                                   % Pa
    eta_p = max(5.0, interp1(mu_cls, eta_cls, mu_p, 'linear', 'extrap'));
    k_p   = max(200, interp1(mu_cls, k_cls, mu_p, 'linear', 'extrap'));
    c_p   = max(1.0, interp1(mu_cls, c_cls, mu_p, 'linear', 'extrap'));

    % Preload inside the interlock window slightly stiffens the tissue (Exp. 07 model)
    mu_eff = mu_p * (1 + contact_alpha * (preload(p) - F_preload_target) / k_A);

    % Steady-state exciter acceleration at f_exc
    A_src = abs(-(w0^2) / ((k_p - m*w0^2) + 1i*c_p*w0)) * F0;
    src   = A_src * sin(w0 * t);

    u1 = shear_wave_propagation_model(t, src, x_sensor1, mu_eff, eta_p, rho_tissue, f_exc);
    u2 = shear_wave_propagation_model(t, src, x_sensor2, mu_eff, eta_p, rho_tissue, f_exc);
    sensor_params.seed = 50000 + 2*p;
    u1 = sensor_model(u1, sensor_params);
    sensor_params.seed = 50000 + 2*p + 1;
    u2 = sensor_model(u2, sensor_params);

    [X1, X2] = fourier_pair(t, u1, u2, f_exc, 0.2);
    dphi = mod(angle(X1 * conj(X2)), 2*pi);        % valid for c > f*dx = 2 m/s
    cs_p = w0 * delta_x / dphi;
    E_meas(p) = 3 * rho_tissue * cs_p^2 / 1000;    % kPa (apparent, 50 Hz)
end

%% 3. Triage decision rules (README.md, Section 2)
E_thresh_moderate = 65.0;  % kPa
E_thresh_high     = 120.0; % kPa
dT_watch_thresh   = 1.00;  % degC: Grade 0 requires Delta T < 1.0
dT_charcot_thresh = 2.20;  % degC (contralateral threshold used in the literature)

triage_grade = zeros(N_total, 1);
for i = 1:N_total
    if dT_meas(i) >= dT_charcot_thresh
        triage_grade(i) = 3;          % RED: acute Charcot / inflammatory flare
    elseif E_meas(i) > E_thresh_high
        triage_grade(i) = 2;          % ORANGE: advanced stiffening
    elseif E_meas(i) >= E_thresh_moderate || dT_meas(i) >= dT_watch_thresh
        triage_grade(i) = 1;          % YELLOW: moderate risk
    else
        triage_grade(i) = 0;          % GREEN: low risk
    end
end

%% 4. Performance metrics on the synthetic cohort
conf_mat = zeros(4, 4);               % rows = true grade, cols = predicted grade
for i = 1:N_total
    conf_mat(ground_truth(i) + 1, triage_grade(i) + 1) = conf_mat(ground_truth(i) + 1, triage_grade(i) + 1) + 1;
end
accuracy_pct = trace(conf_mat) / N_total * 100;
per_class_recall = diag(conf_mat) ./ sum(conf_mat, 2) * 100;

charcot_true = (ground_truth == 3);
charcot_pred = (triage_grade == 3);
charcot_sens = sum(charcot_true & charcot_pred) / sum(charcot_true) * 100;
charcot_spec = sum(~charcot_true & ~charcot_pred) / sum(~charcot_true) * 100;

risk_true = (ground_truth >= 1);      % any abnormal group
risk_pred = (triage_grade >= 1);
risk_sens = sum(risk_true & risk_pred) / sum(risk_true) * 100;
risk_spec = sum(~risk_true & ~risk_pred) / sum(~risk_true) * 100;

E_bias_pct = (E_meas - E_true) ./ E_true * 100;

%% Console Output
fprintf('\n========================================================================\n');
fprintf('  THISULINK EXPERIMENT 12: DUAL-MODALITY TRIAGE - SIMULATION RESULTS\n');
fprintf('  *** Synthetic cohort + simulated sensors. NOT clinical accuracy. ***\n');
fprintf('========================================================================\n');
fprintf('Synthetic cohort              : N = %d (%d healthy, %d early, %d neuropathy, %d Charcot)\n', ...
    N_total, N1, N2, N3, N4);
fprintf('Simulated E measurement       : 50 Hz dual-ADXL355 phase difference, preload %.2f-%.2f N\n', ...
    min(preload), max(preload));
fprintf('  E_meas vs E_true            : mean %+.2f%%, range %+.2f%% to %+.2f%% (viscous bias + noise)\n', ...
    mean(E_bias_pct), min(E_bias_pct), max(E_bias_pct));
fprintf('Simulated Delta T noise (SD)  : %.2f degC\n', dT_noise_sd);
fprintf('Thresholds                    : E %.0f / %.0f kPa, Delta T %.1f / %.1f degC\n', ...
    E_thresh_moderate, E_thresh_high, dT_watch_thresh, dT_charcot_thresh);
fprintf('------------------------------------------------------------------------\n');
fprintf('Confusion matrix (rows = true group, cols = predicted grade 0..3):\n');
for r = 1:4
    fprintf('  true %d : %4d %4d %4d %4d   (recall %6.2f%%)\n', r-1, conf_mat(r, :), per_class_recall(r));
end
fprintf('------------------------------------------------------------------------\n');
fprintf('SIMULATION METRICS (synthetic data):\n');
fprintf('  4-class agreement (accuracy): %.2f%% (%d / %d)\n', accuracy_pct, trace(conf_mat), N_total);
fprintf('  Charcot-flag sensitivity    : %.2f%%\n', charcot_sens);
fprintf('  Charcot-flag specificity    : %.2f%%\n', charcot_spec);
fprintf('  Any-risk (grade>=1) sens.   : %.2f%%\n', risk_sens);
fprintf('  Any-risk (grade>=1) spec.   : %.2f%%\n', risk_spec);
fprintf('These numbers depend entirely on the assumed group distributions and are\n');
fprintf('not evidence of diagnostic performance in patients.\n');
fprintf('========================================================================\n\n');

%% Results Directory
resultsFolder = results_folder(expDir);   % -> outputs/<experiment>/

%% Plot 1: 2D triage map (measured values)
figure('Name', 'THISULINK - Multimodal Triage Space', 'Color', 'w');
hold on;
fill([0 65 65 0], [0 0 1.0 1.0], [0.85 1.0 0.85], 'EdgeColor', 'none');              % Green
fill([0 65 65 0], [1.0 1.0 2.2 2.2], [1.0 1.0 0.80], 'EdgeColor', 'none');          % Yellow (thermal)
fill([65 120 120 65], [0 0 2.2 2.2], [1.0 1.0 0.80], 'EdgeColor', 'none');          % Yellow
fill([120 250 250 120], [0 0 2.2 2.2], [1.0 0.88 0.80], 'EdgeColor', 'none');       % Orange
fill([0 250 250 0], [2.2 2.2 4.0 4.0], [1.0 0.80 0.80], 'EdgeColor', 'none');       % Red

p0 = plot(E_meas(ground_truth==0), dT_meas(ground_truth==0), 'o', 'MarkerFaceColor', [0 0.6 0], ...
    'MarkerEdgeColor', 'k', 'MarkerSize', 7);
p1 = plot(E_meas(ground_truth==1), dT_meas(ground_truth==1), '^', 'MarkerFaceColor', [0.9 0.7 0], ...
    'MarkerEdgeColor', 'k', 'MarkerSize', 7);
p2 = plot(E_meas(ground_truth==2), dT_meas(ground_truth==2), 's', 'MarkerFaceColor', [0.85 0.33 0.1], ...
    'MarkerEdgeColor', 'k', 'MarkerSize', 7);
p3 = plot(E_meas(ground_truth==3), dT_meas(ground_truth==3), 'p', 'MarkerFaceColor', 'r', ...
    'MarkerEdgeColor', 'k', 'MarkerSize', 11);

xlim([15, 250]);
ylim([0, 4.0]);
xlabel('Simulated SWE Young Modulus E (kPa)');
ylabel('Simulated contralateral \DeltaT (deg C)');
title(sprintf('Triage map - SYNTHETIC cohort (N = %d), agreement %.1f%%', N_total, accuracy_pct));
legend([p0, p1, p2, p3], {'True group 0: Healthy', 'True group 1: Early', ...
    'True group 2: Neuropathy', 'True group 3: Charcot'}, 'Location', 'eastoutside');
grid on;
saveas(gcf, fullfile(resultsFolder, 'multimodal_triage_scatter.png'));

%% Plot 2: Confusion matrix
figure('Name', 'THISULINK - Confusion Matrix', 'Color', 'w');
imagesc(conf_mat);
colormap(flipud(gray));
colorbar;
axis image;
set(gca, 'XTick', 1:4, 'XTickLabel', {'Grade 0', 'Grade 1', 'Grade 2', 'Grade 3'});
set(gca, 'YTick', 1:4, 'YTickLabel', {'Group 0', 'Group 1', 'Group 2', 'Group 3'});
xlabel('Predicted triage grade');
ylabel('True synthetic group');
title(sprintf('Synthetic-cohort confusion matrix (agreement %.1f%%)', accuracy_pct));
for r = 1:4
    for c = 1:4
        if conf_mat(r, c) > max(conf_mat(:)) / 2
            txtColor = [1 1 1];
        else
            txtColor = [0 0 0];
        end
        text(c, r, num2str(conf_mat(r, c)), 'HorizontalAlignment', 'center', ...
            'FontWeight', 'bold', 'FontSize', 12, 'Color', txtColor);
    end
end
saveas(gcf, fullfile(resultsFolder, 'triage_confusion_matrix.png'));
