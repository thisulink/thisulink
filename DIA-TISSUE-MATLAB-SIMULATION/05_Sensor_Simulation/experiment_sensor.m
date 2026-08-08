%% DIA-TISSUE
% Experiment 5: ADXL355-Like Sensor Simulation
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
%% Sensor Parameters
params.range_g = 2.0;
params.bits = 20;
params.bandwidth = 150.0;
params.noise_density = 0.000250;
params.bias = 0.010000;
%% Model A
k = k_A;
c = c_A;
%% Generate Signal
x0 = [0;0];
[t_sim,X] = ode45(@(tt,x)tissue_model(tt,x,m,c,k,F0,f_exc),t,x0);
displacement = X(:,1);
velocity = X(:,2);
force = F0.*sin(2*pi*f_exc.*t_sim);
true_acc = (force-c.*velocity-k.*displacement)./m;
%% Sensor Simulation
[measured_acc,info] = sensor_model(true_acc,params);
%% Error Analysis
error_signal = measured_acc-true_acc;
true_rms = rms(true_acc);
noise_rms = info.noise_rms;
error_rms = rms(error_signal);
snr_db = 20*log10(true_rms/error_rms);
%% Display Results
fprintf('\n========================================\n');
fprintf(' DIA-TISSUE ADXL355-LIKE SENSOR TEST\n');
fprintf('========================================\n');
fprintf('\nSIMULATED SENSOR CONFIGURATION\n');
fprintf('Range                : +/- %.1f g\n',params.range_g);
fprintf('Resolution            : %d bits\n',params.bits);
fprintf('Bandwidth             : %.1f Hz\n',params.bandwidth);
fprintf('Noise density         : %.6f m/s^2/sqrt(Hz)\n',params.noise_density);
fprintf('Bias                  : %.6f m/s^2\n',params.bias);
fprintf('\nRESULTS\n');
fprintf('True signal RMS       : %.6f m/s^2\n',true_rms);
fprintf('Model noise RMS       : %.6f m/s^2\n',noise_rms);
fprintf('Total error RMS       : %.6f m/s^2\n',error_rms);
fprintf('Estimated SNR         : %.2f dB\n',snr_db);
fprintf('Quantization step     : %.9f m/s^2\n',info.quantization_step);
fprintf('========================================\n');
%% Results Folder
resultsFolder = fullfile(fileparts(mfilename('fullpath')),'results');
if ~exist(resultsFolder,'dir')
    mkdir(resultsFolder);
end
%% Figure 1 - True vs Measured Acceleration
figure;
plot(t_sim,true_acc,'LineWidth',1.2);
hold on;
plot(t_sim,measured_acc,'LineWidth',1.0);
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');
title('DIA-TISSUE - True vs Simulated Sensor Acceleration');
legend('True Acceleration','Measured Acceleration','Location','best');
grid on;
saveas(gcf,fullfile(resultsFolder,'true_vs_measured_acceleration.png'));
%% Figure 2 - Measurement Error
figure;
plot(t_sim,error_signal,'LineWidth',1.0);
xlabel('Time (s)');
ylabel('Measurement Error (m/s^2)');
title('DIA-TISSUE - Simulated Accelerometer Error');
grid on;
saveas(gcf,fullfile(resultsFolder,'measurement_error.png'));