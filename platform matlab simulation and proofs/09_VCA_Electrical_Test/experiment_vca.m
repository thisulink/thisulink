%% THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM
% Experiment 9: Voice Coil Actuator (VCA) Electromechanical Characterization
% Hardware: BEI Kimco / Akribis Linear Voice Coil Actuator Subsystem
% Bandwidth: 10 - 300 Hz Diagnostic Chirp
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

%% Actuator Specifications
R   = vca_R;       % 8.20 Ohm (Voice coil DC resistance)
L   = vca_L;       % 0.00120 H (1.20 mH voice coil inductance)
Kf  = vca_Kf;      % 2.40 N/A (Force sensitivity constant)
Ke  = vca_Ke;      % 2.40 V/(m/s) (Back-EMF constant)
V0  = vca_Vdrive;  % 1.20 V peak driving voltage

%% Nominal Operating Point (50 Hz Diagnostic Center)
f_nom = f_exc; % 50 Hz
w_nom = 2 * pi * f_nom;

Z_nom = R + 1i * (w_nom * L);
Z_mag_nom = abs(Z_nom);
Z_phase_deg = angle(Z_nom) * (180 / pi);

I_peak_nom = V0 / Z_mag_nom;
I_rms_nom  = I_peak_nom / sqrt(2);

F_peak_nom = Kf * I_peak_nom;
F_rms_nom  = Kf * I_rms_nom;

% Electrical and Thermal Power Dissipation
P_elec_rms = (I_rms_nom^2) * R;

%% Frequency Sweep (1 to 500 Hz characterization sweep)
f_sweep = linspace(1, 500, 500);
w_sweep = 2 * pi * f_sweep;

Z_sweep = sqrt(R^2 + (w_sweep .* L).^2);
I_sweep_peak = V0 ./ Z_sweep;
F_sweep_peak = Kf .* I_sweep_peak;
P_sweep_rms  = ((I_sweep_peak ./ sqrt(2)).^2) .* R;

%% Console Output
fprintf('\n========================================================================\n');
fprintf('  THISULINK EXPERIMENT 09: VCA ELECTROMECHANICAL & POWER CHARACTERISTICS \n');
fprintf('========================================================================\n');
fprintf('Actuator Type                 : Linear Voice Coil Actuator (VCA)\n');
fprintf('Coil DC Resistance (R)        : %.2f Ohm\n', R);
fprintf('Coil Inductance (L)           : %.3f mH (%.6f H)\n', L*1000, L);
fprintf('Force Constant (Kf)           : %.2f N/A\n', Kf);
fprintf('Back-EMF Constant (Ke)        : %.2f V/(m/s)\n', Ke);
fprintf('Drive Voltage Amplitude (V0)  : %.2f V peak\n', V0);
fprintf('------------------------------------------------------------------------\n');
fprintf('NOMINAL EVALUATION (f = %.1f Hz):\n', f_nom);
fprintf('  Electrical Impedance |Z|    : %.3f Ohm (Phase = %.2f deg)\n', Z_mag_nom, Z_phase_deg);
fprintf('  Peak Coil Current           : %.4f A (%.1f mA)\n', I_peak_nom, I_peak_nom*1000);
fprintf('  RMS Coil Current            : %.4f A (%.1f mA)\n', I_rms_nom, I_rms_nom*1000);
fprintf('  Peak Output Dynamic Force   : %.4f N (%.1f mN)\n', F_peak_nom, F_peak_nom*1000);
fprintf('  RMS Dynamic Force           : %.4f N (%.1f mN)\n', F_rms_nom, F_rms_nom*1000);
fprintf('  Average Electrical Power    : %.4f W (%.1f mW)\n', P_elec_rms, P_elec_rms*1000);
fprintf('  Target Dynamic Force F0     : %.3f N (100 mN safe skin contact)\n', F0);
fprintf('  Power Status                : ULTRA-LOW POWER (< 0.1 W, Full Battery Autonomy)\n');
fprintf('========================================================================\n\n');

%% Results Directory
resultsFolder = fullfile(expDir, 'results');
if ~exist(resultsFolder, 'dir')
    mkdir(resultsFolder);
end

%% Plot 1: Electrical Impedance vs Frequency
figure('Name', 'THISULINK - VCA Impedance', 'Color', 'w');
plot(f_sweep, Z_sweep, 'LineWidth', 1.8, 'Color', [0.0 0.45 0.74]);
hold on;
xline(f_nom, '--g', sprintf('f_{nom} = %.0f Hz (|Z| = %.2f \\Omega)', f_nom, Z_mag_nom), 'LineWidth', 1.3);
xlabel('Frequency (Hz)');
ylabel('Impedance |Z| (\Omega)');
title('THISULINK Voice Coil Actuator Electrical Impedance');
grid on;
saveas(gcf, fullfile(resultsFolder, 'vca_impedance.png'));

%% Plot 2: Dynamic Current Response
figure('Name', 'THISULINK - VCA Current', 'Color', 'w');
plot(f_sweep, I_sweep_peak * 1000, 'LineWidth', 1.8, 'Color', [0.85 0.33 0.10]);
hold on;
xline(f_nom, '--g', sprintf('f_{nom} = %.0f Hz (I_{peak} = %.1f mA)', f_nom, I_peak_nom*1000), 'LineWidth', 1.3);
xlabel('Frequency (Hz)');
ylabel('Peak Coil Current (mA)');
title('THISULINK VCA Drive Current vs Frequency (1.20 V Peak)');
grid on;
saveas(gcf, fullfile(resultsFolder, 'vca_current_response.png'));

%% Plot 3: Dynamic Force Output vs Frequency
figure('Name', 'THISULINK - VCA Force Output', 'Color', 'w');
plot(f_sweep, F_sweep_peak * 1000, 'LineWidth', 1.8, 'Color', [0.47 0.67 0.19]);
hold on;
xline(f_nom, '--g', sprintf('f_{nom} = %.0f Hz (F_{peak} = %.1f mN)', f_nom, F_peak_nom*1000), 'LineWidth', 1.3);
yline(F0 * 1000, ':b', sprintf('Nominal F_0 = %.0f mN', F0*1000), 'LineWidth', 1.5);
xlabel('Frequency (Hz)');
ylabel('Dynamic Force Peak (mN)');
title('THISULINK Dynamic Excitation Force Output Across 10 - 300 Hz');
grid on;
saveas(gcf, fullfile(resultsFolder, 'vca_force_response.png'));

%% Plot 4: Power Consumption vs Frequency
figure('Name', 'THISULINK - VCA Power', 'Color', 'w');
plot(f_sweep, P_sweep_rms * 1000, 'LineWidth', 1.8, 'Color', [0.49 0.18 0.56]);
hold on;
yline(350, '--r', 'Max Battery Budget (350 mW)', 'LineWidth', 1.3);
xlabel('Frequency (Hz)');
ylabel('RMS Power Consumption (mW)');
title('THISULINK Actuator Electrical Power Consumption (< 100 mW)');
grid on;
saveas(gcf, fullfile(resultsFolder, 'vca_power_consumption.png'));
