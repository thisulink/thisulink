%% DIA-TISSUE
% Experiment 4: FFT Analysis
% SIMULATION ASSUMPTION - NOT A CLINICAL VALUE
clear;
clc;
close all;
%% Project Path
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot,'common'));
addpath(fileparts(mfilename('fullpath')));
%% Load Common Parameters
simulation_parameters;
%% Local FFT Parameters
fs_fft = 4000;
T_fft = 2.0;
t_fft = (0:1/fs_fft:T_fft-1/fs_fft)';
%% Model A
k = k_A;
c = c_A;
fprintf('\n========================================\n');
fprintf(' DIA-TISSUE FFT ANALYSIS\n');
fprintf('========================================\n');
fprintf('Model: A - Compliant\n');
fprintf('Excitation frequency: %.2f Hz\n',f_exc);
fprintf('Sampling frequency: %.2f Hz\n',fs_fft);
%% Steady-State Mechanical Response
w = 2*pi*f_exc;
dynamic_stiffness = (k-m*w^2)+1i*(c*w);
X_complex = F0/dynamic_stiffness;
A_complex = -w^2*X_complex;
%% Generate Steady-State Acceleration
acceleration = real(A_complex*exp(1i*w*t_fft));
%% FFT
[f,magnitude] = fft_analysis(acceleration,fs_fft);
%% Remove DC
searchMagnitude = magnitude;
searchMagnitude(1) = 0;
%% Find Dominant Frequency
[peakMagnitude,index] = max(searchMagnitude);
dominantFrequency = f(index);
%% Display Results
fprintf('\nFFT RESULTS\n');
fprintf('Expected excitation frequency : %.2f Hz\n',f_exc);
fprintf('Dominant FFT frequency        : %.2f Hz\n',dominantFrequency);
fprintf('FFT peak magnitude            : %.4f m/s^2\n',peakMagnitude);
fprintf('Frequency resolution          : %.4f Hz\n',fs_fft/length(acceleration));
fprintf('========================================\n');
%% Results Folder
resultsFolder = fullfile(fileparts(mfilename('fullpath')),'results');
if ~exist(resultsFolder,'dir')
    mkdir(resultsFolder);
end
%% Graph 1 - Steady-State Acceleration
figure;
plot(t_fft,acceleration,'LineWidth',1.2);
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');
title('DIA-TISSUE - Steady-State Acceleration');
grid on;
saveas(gcf,fullfile(resultsFolder,'steady_state_acceleration.png'));
%% Graph 2 - FFT Spectrum
figure;
plot(f,magnitude,'LineWidth',1.3);
xlim([0 150]);
xlabel('Frequency (Hz)');
ylabel('Acceleration Magnitude (m/s^2)');
title('DIA-TISSUE - Acceleration FFT Spectrum');
grid on;
hold on;
xline(f_exc,'--',sprintf('Excitation = %.0f Hz',f_exc));
hold off;
saveas(gcf,fullfile(resultsFolder,'acceleration_fft_spectrum.png'));