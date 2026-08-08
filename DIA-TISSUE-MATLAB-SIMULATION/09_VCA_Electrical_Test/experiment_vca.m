%% DIA-TISSUE
% Experiment 9: VCA Electrical Test
% SIMULATION ASSUMPTION - PLACEHOLDER ACTUATOR PARAMETERS
clear;
clc;
close all;
%% Project Path
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot,'common'));
%% Load Common Parameters
simulation_parameters;
%% VCA Placeholder Parameters
R = 8.0000;
L = 0.005000;
Kf = 1.0000;
Ke = 1.0000;
%% Command
f_vca = f_exc;
V_peak = 1.0000;
w = 2*pi*f_vca;
%% Electrical Impedance
Z = R + 1i*w*L;
Z_mag = abs(Z);
%% Simulated Current
I_peak = V_peak/Z_mag;
I_rms = I_peak/sqrt(2);
%% Force
F_peak = Kf*I_peak;
F_rms = Kf*I_rms;
%% Theoretical Check
expected_I_peak = V_peak/Z_mag;
expected_F_peak = Kf*expected_I_peak;
%% Display Results
fprintf('\n=============================================\n');
fprintf(' DIA-TISSUE VCA ELECTRICAL TEST\n');
fprintf('=============================================\n');
fprintf('\nPLACEHOLDER PARAMETERS\n');
fprintf('REPLACE AFTER EXACT VCA IS SELECTED\n');
fprintf('\nResistance R       = %.4f Ohm\n',R);
fprintf('Inductance L       = %.6f H\n',L);
fprintf('Force constant Kf  = %.4f N/A\n',Kf);
fprintf('Back-EMF Ke        = %.4f V/(m/s)\n',Ke);
fprintf('\nCOMMAND\n');
fprintf('Frequency          = %.2f Hz\n',f_vca);
fprintf('Voltage peak       = %.4f V\n',V_peak);
fprintf('\nSIMULATED RESPONSE\n');
fprintf('Peak current       = %.6f A\n',I_peak);
fprintf('RMS current        = %.6f A\n',I_rms);
fprintf('Peak force         = %.6f N\n',F_peak);
fprintf('RMS force          = %.6f N\n',F_rms);
fprintf('\nTHEORETICAL CHECK\n');
fprintf('|Electrical Z|     = %.6f Ohm\n',Z_mag);
fprintf('Expected I peak    = %.6f A\n',expected_I_peak);
fprintf('Expected F peak    = %.6f N\n',expected_F_peak);
fprintf('\nOriginal ideal F0  = %.6f N\n',F0);
fprintf('=============================================\n');
%% Results Folder
resultsFolder = fullfile(fileparts(mfilename('fullpath')),'results');
if ~exist(resultsFolder,'dir')
    mkdir(resultsFolder);
end
%% Frequency Response of Electrical Impedance
frequency = linspace(1,500,500);
omega = 2*pi*frequency;
Z_frequency = sqrt(R^2+(omega*L).^2);
%% Figure 1 - Electrical Impedance
figure;
plot(frequency,Z_frequency,'LineWidth',1.5);
xlabel('Frequency (Hz)');
ylabel('|Z| (Ohm)');
title('DIA-TISSUE - VCA Electrical Impedance');
grid on;
saveas(gcf,fullfile(resultsFolder,'vca_impedance.png'));
%% Figure 2 - Current Response
current_response = V_peak./Z_frequency;
figure;
plot(frequency,current_response,'LineWidth',1.5);
xlabel('Frequency (Hz)');
ylabel('Peak Current (A)');
title('DIA-TISSUE - VCA Current Response');
grid on;
saveas(gcf,fullfile(resultsFolder,'vca_current_response.png'));
%% Figure 3 - Force Response
force_response = Kf*current_response;
figure;
plot(frequency,force_response,'LineWidth',1.5);
xlabel('Frequency (Hz)');
ylabel('Peak Force (N)');
title('DIA-TISSUE - VCA Force Response');
grid on;
saveas(gcf,fullfile(resultsFolder,'vca_force_response.png'));