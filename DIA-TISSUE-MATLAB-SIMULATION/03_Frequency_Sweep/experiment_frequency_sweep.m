%% DIA-TISSUE
% Experiment 3: Frequency Response Sweep
% SIMULATION ASSUMPTION - NOT A CLINICAL VALUE
%
% Purpose:
% Study how acceleration and displacement response change
% with excitation frequency for three mechanical models.

clear;
clc;
close all;

%% Project Path
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot,'common'));

%% Load Parameters
simulation_parameters;

%% Models
k_values = [k_A k_B k_C];
c_values = [c_A c_B c_C];

model_names = {
    'Model A - Compliant'
    'Model B - Moderately Increased Stiffness'
    'Model C - Substantially Increased Stiffness'
};

numModels = 3;

%% Frequency Sweep
frequencies = f_start:frequency_step:f_end;
numFreq = length(frequencies);

%% Storage
acc_amp = zeros(numFreq,numModels);
disp_amp = zeros(numFreq,numModels);
phase_deg = zeros(numFreq,numModels);

%% Analytical Steady-State Frequency Response
%
% Mechanical displacement transfer function:
% X/F = 1 / (k - m*w^2 + j*c*w)
%
% Acceleration:
% A = -w^2 * X

fprintf('\n=========================================\n');
fprintf(' DIA-TISSUE FREQUENCY SWEEP\n');
fprintf('=========================================\n');
fprintf('Frequency range : %.1f - %.1f Hz\n',f_start,f_end);
fprintf('Frequency step  : %.1f Hz\n',frequency_step);
fprintf('Number of points: %d\n',numFreq);
fprintf('\nRunning sweep...\n');

%% Sweep Models
for model = 1:numModels
    k = k_values(model);
    c = c_values(model);
    
    for n = 1:numFreq
        f = frequencies(n);
        w = 2*pi*f;
        
        %% Mechanical Dynamic Stiffness
        denominator = (k - m*w^2) + 1i*(c*w);
        
        %% Displacement FRF
        Hx = 1./denominator;
        
        %% Displacement Amplitude
        disp_amp(n,model) = abs(Hx)*F0;
        
        %% Acceleration FRF
        Ha = -(w^2).*Hx;
        
        %% Acceleration Amplitude
        acc_amp(n,model) = abs(Ha)*F0;
        
        %% Acceleration Phase Relative to Force
        phase_deg(n,model) = angle(Ha)*180/pi;
    end
end

%% Find Acceleration Response Peaks
peak_frequency = zeros(numModels,1);
peak_acceleration = zeros(numModels,1);

for model = 1:numModels
    [peak_acceleration(model),index] = max(acc_amp(:,model));
    peak_frequency(model) = frequencies(index);
end

%% Theoretical Undamped Natural Frequencies
fn = (1/(2*pi)).*sqrt(k_values./m);

%% Display Results
fprintf('\n=========================================\n');
fprintf(' FREQUENCY SWEEP RESULTS\n');
fprintf('=========================================\n');

for model = 1:numModels
    fprintf('\n%s\n',model_names{model});
    fprintf('k = %.1f N/m\n',k_values(model));
    fprintf('Theoretical natural frequency = %.2f Hz\n',fn(model));
    fprintf('Peak acceleration frequency = %.2f Hz\n',peak_frequency(model));
    fprintf('Peak acceleration = %.4f m/s^2\n',peak_acceleration(model));
end

fprintf('\n=========================================\n');

%% Results Folder
resultsFolder = fullfile(fileparts(mfilename('fullpath')),'results');

if ~exist(resultsFolder,'dir')
    mkdir(resultsFolder);
end

%% Figure 1 - Acceleration Frequency Response
figure;
plot(frequencies,acc_amp(:,1),'LineWidth',1.5);
hold on;
plot(frequencies,acc_amp(:,2),'LineWidth',1.5);
plot(frequencies,acc_amp(:,3),'LineWidth',1.5);

xlabel('Excitation Frequency (Hz)');
ylabel('Acceleration Amplitude (m/s^2)');
title('DIA-TISSUE - Acceleration Frequency Response');
legend(model_names,'Location','best');
grid on;

saveas(gcf,fullfile(resultsFolder,'acceleration_frequency_response.png'));

%% Figure 2 - Displacement Frequency Response
figure;
plot(frequencies,disp_amp(:,1),'LineWidth',1.5);
hold on;
plot(frequencies,disp_amp(:,2),'LineWidth',1.5);
plot(frequencies,disp_amp(:,3),'LineWidth',1.5);

xlabel('Excitation Frequency (Hz)');
ylabel('Displacement Amplitude (m)');
title('DIA-TISSUE - Displacement Frequency Response');
legend(model_names,'Location','best');
grid on;

saveas(gcf,fullfile(resultsFolder,'displacement_frequency_response.png'));

%% Figure 3 - Phase Response
figure;
plot(frequencies,phase_deg(:,1),'LineWidth',1.5);
hold on;
plot(frequencies,phase_deg(:,2),'LineWidth',1.5);
plot(frequencies,phase_deg(:,3),'LineWidth',1.5);

xlabel('Excitation Frequency (Hz)');
ylabel('Phase (degrees)');
title('DIA-TISSUE - Phase Response');
legend(model_names,'Location','best');
grid on;

saveas(gcf,fullfile(resultsFolder,'phase_response.png'));