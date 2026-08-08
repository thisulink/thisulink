%% DIA-TISSUE SIMULATION PARAMETERS
% SIMULATION ASSUMPTIONS - NOT CLINICAL
clearvars -except ans
%% Common Parameters
m = 0.0200;          % Effective mass (kg)
f_exc = 30.0;        % Excitation frequency (Hz)
F0 = 0.100;          % Force amplitude (N)
%% Model A
k_A = 800.0;         % N/m
c_A = 2.00;          % N*s/m
fn_A = (1/(2*pi))*sqrt(k_A/m);
zeta_A = c_A/(2*sqrt(k_A*m));
%% Model B
k_B = 1400.0;        % N/m
c_B = 2.00;          % N*s/m
fn_B = (1/(2*pi))*sqrt(k_B/m);
zeta_B = c_B/(2*sqrt(k_B*m));
%% Model C
k_C = 2200.0;        % N/m
c_C = 2.00;          % N*s/m
fn_C = (1/(2*pi))*sqrt(k_C/m);
zeta_C = c_C/(2*sqrt(k_C*m));
%% Time Parameters
fs = 4000;           % Sampling frequency (Hz)
T = 1.0;             % Simulation duration (s)
t = (0:1/fs:T-1/fs)';
%% Frequency Sweep Parameters
f_start = 10;
f_end = 500;
frequency_step = 1;
%% Display
fprintf('\n');
fprintf('========================================\n');
fprintf(' DIA-TISSUE SIMULATION PARAMETERS\n');
fprintf(' SIMULATION ASSUMPTIONS - NOT CLINICAL\n');
fprintf('========================================\n');
fprintf('\nEffective mass = %.4f kg\n',m);
fprintf('Excitation     = %.1f Hz\n',f_exc);
fprintf('Force amplitude = %.3f N\n',F0);
fprintf('\nMODEL A\n');
fprintf('k = %.1f N/m\n',k_A);
fprintf('c = %.2f N*s/m\n',c_A);
fprintf('Natural frequency = %.2f Hz\n',fn_A);
fprintf('Damping ratio = %.3f\n',zeta_A);
fprintf('\nMODEL B\n');
fprintf('k = %.1f N/m\n',k_B);
fprintf('c = %.2f N*s/m\n',c_B);
fprintf('Natural frequency = %.2f Hz\n',fn_B);
fprintf('Damping ratio = %.3f\n',zeta_B);
fprintf('\nMODEL C\n');
fprintf('k = %.1f N/m\n',k_C);
fprintf('c = %.2f N*s/m\n',c_C);
fprintf('Natural frequency = %.2f Hz\n',fn_C);
fprintf('Damping ratio = %.3f\n',zeta_C);
fprintf('\n========================================\n');