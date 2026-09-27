%% THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM
% Experiment 7: Contact Preload Force Sensitivity & Tissue Non-Linearity
% Proves Necessity of THISULINK 1.50 N Contact Interlock Gate
% SIH 2026 Grand Finale - THISULINK Diagnostic Verification

% (No clear/clc/close all here: the master runner executes every experiment
%  in its own workspace, and clearing would break callers.)

%% Path Setup
expDir = fileparts(mfilename('fullpath'));
if isempty(expDir), expDir = pwd; end
projectRoot = fileparts(expDir);
addpath(fullfile(projectRoot, 'common'));

%% Load Calibrated Parameters
simulation_parameters;

%% Contact Force Sensitivity Parameters
baseline_k   = k_A;                % 800 N/m (Class 1 Healthy Control)
target_force = F_preload_target;   % 1.50 N
alpha        = contact_alpha;      % 180.0 (N/m)/N contact stiffening sensitivity

% Sweep contact preload forces from loose contact to excessive compression
contact_forces = [0.8, 1.1, 1.4, 1.5, 1.6, 2.0, 2.5, 3.0];
numForces = length(contact_forces);

%% Preallocate Storage
effective_k       = zeros(numForces, 1);
natural_frequency = zeros(numForces, 1);
effective_cs      = zeros(numForces, 1);
effective_E_kPa   = zeros(numForces, 1);
acceleration_amp  = zeros(numForces, 1);
measurement_error_percent = zeros(numForces, 1);

w = 2 * pi * f_exc;

%% Calculate Non-Linear Contact Behavior
for i = 1:numForces
    F_contact = contact_forces(i);
    
    % Non-linear pre-stress stiffening model:
    % k_eff = k0 + alpha * (F_contact - F_target)
    eff_k = baseline_k + alpha * (F_contact - target_force);
    effective_k(i) = eff_k;
    
    % Natural frequency shift
    fn_curr = (1 / (2 * pi)) * sqrt(eff_k / m);
    natural_frequency(i) = fn_curr;
    
    % Apparent shear modulus and wave speed shift.
    % Assumption: the apparent shear modulus scales with the same relative
    % pre-stress factor as the contact stiffness, mu_eff = mu_A * k_eff / k_A.
    % (The previous rigid-punch estimate mu = k/(8*r0) gave 20 kPa for Class 1,
    % inconsistent with mu_A = 14.5 kPa used everywhere else.)
    mu_eff = mu_A * eff_k / baseline_k;
    % Apparent (viscoelastic) phase velocity at f_exc from the shared model
    [~, wave_eff] = shear_wave_propagation_model(t, zeros(size(t)), delta_x, ...
        mu_eff, eta_A, rho_tissue, f_exc);
    cs_curr = wave_eff.cs;
    effective_cs(i) = cs_curr;
    effective_E_kPa(i) = (3 * mu_eff) / 1000;
    
    % Steady-state acceleration amplitude under 100 mN dynamic excitation
    denominator = (eff_k - m * w^2) + 1i * (c_A * w);
    disp_amplitude = abs(F0 / denominator);
    acceleration_amp(i) = (w^2) * disp_amplitude;
    
    % Error relative to calibrated target 1.50 N preload
    eff_k_target = baseline_k;
    measurement_error_percent(i) = (eff_k - eff_k_target) / eff_k_target * 100;  % signed
end

%% Worst case INSIDE the interlock window (evaluated at the window edges)
k_win   = baseline_k + alpha * ([F_preload_min, F_preload_max] - target_force);
err_win = max(abs(k_win - baseline_k)) / baseline_k * 100;
fn_win  = max(abs((1/(2*pi)) * sqrt(k_win / m) - fn_A));
[~, wv_lo] = shear_wave_propagation_model(t, zeros(size(t)), delta_x, mu_A*k_win(1)/baseline_k, eta_A, rho_tissue, f_exc);
[~, wv_0 ] = shear_wave_propagation_model(t, zeros(size(t)), delta_x, mu_A, eta_A, rho_tissue, f_exc);
[~, wv_hi] = shear_wave_propagation_model(t, zeros(size(t)), delta_x, mu_A*k_win(2)/baseline_k, eta_A, rho_tissue, f_exc);
cs_win  = max(abs([wv_lo.cs, wv_hi.cs] - wv_0.cs));

%% Console Output
fprintf('\n========================================================================\n');
fprintf('  THISULINK EXPERIMENT 07: CONTACT FORCE SENSITIVITY & INTERLOCK PROOF   \n');
fprintf('========================================================================\n');
fprintf('Baseline Tissue Stiffness (k0): %.1f N/m\n', baseline_k);
fprintf('Calibrated Target Preload     : %.2f N\n', target_force);
fprintf('Contact Stiffening Alpha      : %.1f (N/m)/N\n', alpha);
fprintf('Allowable Interlock Window    : %.2f N - %.2f N (1.50 N +/- 0.10 N)\n', ...
    F_preload_min, F_preload_max);
fprintf('------------------------------------------------------------------------\n');
fprintf('Preload(N)\tEffective k\tfn(Hz)\tcs(m/s)\tE(kPa)\tAcc(m/s^2)\tStiffness Error\n');
fprintf('------------------------------------------------------------------------\n');
for i = 1:numForces
    interlock_flag = '';
    if contact_forces(i) >= F_preload_min && contact_forces(i) <= F_preload_max
        interlock_flag = ' [VALID INTERLOCK GATE]';
    elseif contact_forces(i) < F_preload_min
        interlock_flag = ' [REJECT: UNDER-CONTACT]';
    else
        interlock_flag = ' [REJECT: OVER-COMPRESSION]';
    end
    
    fprintf('%.2f N\t\t%.1f N/m\t%.2f\t%.2f\t%.1f\t%.4f\t\t%.1f%%%s\n', ...
        contact_forces(i), effective_k(i), natural_frequency(i), ...
        effective_cs(i), effective_E_kPa(i), acceleration_amp(i), ...
        measurement_error_percent(i), interlock_flag);
end
fprintf('------------------------------------------------------------------------\n');
fprintf('Uncontrolled range %.1f-%.1f N  : stiffness error %+.1f%% to %+.1f%%\n', ...
    contact_forces(1), contact_forces(end), min(measurement_error_percent), max(measurement_error_percent));
fprintf('Inside interlock window        : |stiffness error| <= %.2f%%, |d fn| <= %.2f Hz, |d cs| <= %.3f m/s\n', ...
    err_win, fn_win, cs_win);
fprintf('NOTE: linear pre-stress model with an ASSUMED alpha = %.0f (N/m)/N; loss of\n', alpha);
fprintf('      coupling at very low preload is not modelled.\n');
fprintf('========================================================================\n\n');

%% Results Directory
resultsFolder = results_folder(expDir);   % -> outputs/<experiment>/

%% Plot 1: Contact Preload vs Effective Stiffness
figure('Name', 'THISULINK - Contact Preload Stiffening', 'Color', 'w');
plot(contact_forces, effective_k, 'o-b', 'LineWidth', 1.8, 'MarkerFaceColor', 'b');
hold on;
fill([F_preload_min, F_preload_max, F_preload_max, F_preload_min], ...
     [min(effective_k)-50, min(effective_k)-50, max(effective_k)+50, max(effective_k)+50], ...
     [0.85 1.0 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
xline(target_force, '--g', 'Target Preload (1.50 N)', 'LineWidth', 1.5);
xline(F_preload_min, ':r', 'Min Preload (1.40 N)', 'LineWidth', 1.2);
xline(F_preload_max, ':r', 'Max Preload (1.60 N)', 'LineWidth', 1.2);
xlabel('Static Contact Preload Force (N)');
ylabel('Effective Tissue Stiffness k_{eff} (N/m)');
title('THISULINK Plantar Tissue Pre-Stress Stiffening vs Preload Force');
legend('Tissue Stiffening Curve', '1.5 N +/- 0.1 N Interlock Safe Zone', 'Location', 'northwest');
grid on;
saveas(gcf, fullfile(resultsFolder, 'contact_force_vs_stiffness.png'));

%% Plot 2: Measurement Error vs Contact Force
figure('Name', 'THISULINK - Preload Error', 'Color', 'w');
plot(contact_forces, measurement_error_percent, 's-r', 'LineWidth', 1.8, 'MarkerFaceColor', 'r');
hold on;
fill([F_preload_min, F_preload_max, F_preload_max, F_preload_min], ...
     [min(measurement_error_percent)-5, min(measurement_error_percent)-5, ...
      max(measurement_error_percent)+5, max(measurement_error_percent)+5], ...
     [0.85 1.0 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
yline(err_win, '--g', sprintf('+%.2f%% (window edge)', err_win), 'LineWidth', 1.5);
yline(-err_win, '--g', sprintf('-%.2f%% (window edge)', err_win), 'LineWidth', 1.5);
xlabel('Applied Contact Preload Force (N)');
ylabel('Stiffness Error Relative to 1.50 N Baseline (%)');
title('Plantar Modulus Error vs Contact Force: Why 1.5 N Interlock is Mandatory');
legend('Uncontrolled Operator Error', sprintf('Interlock Zone (|error| <= %.2f%%)', err_win), 'Location', 'northwest');
grid on;
saveas(gcf, fullfile(resultsFolder, 'preload_error_curve.png'));

%% Plot 3: Contact Force vs Apparent Shear Wave Speed
figure('Name', 'THISULINK - Apparent Shear Speed', 'Color', 'w');
plot(contact_forces, effective_cs, 'd-m', 'LineWidth', 1.8, 'MarkerFaceColor', 'm');
hold on;
fill([F_preload_min, F_preload_max, F_preload_max, F_preload_min], ...
     [min(effective_cs)-0.2, min(effective_cs)-0.2, max(effective_cs)+0.2, max(effective_cs)+0.2], ...
     [0.85 1.0 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
xline(target_force, '--g', 'Target (1.50 N)', 'LineWidth', 1.5);
xlabel('Contact Preload Force (N)');
ylabel('Apparent Shear Wave Speed c_s (m/s)');
title('Apparent Shear Wave Velocity Shift Induced by Preload Variability');
grid on;
saveas(gcf, fullfile(resultsFolder, 'contact_force_vs_cs.png'));
