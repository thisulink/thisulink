%% DIA-TISSUE
% Experiment 6: Noise / SNR Analysis
% SIMULATION ASSUMPTION - NOT A CLINICAL VALUE

clear;
clc;
close all;

%% Project Path
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot,'common'));

%% Load Common Parameters
simulation_parameters;

%% Model A
k = k_A;
c = c_A;

%% Sensor Parameters
range_g = 2.0;
bits = 20;
bandwidth = 150.0;
bias = 0.010;

%% Noise Density Levels
noise_density_levels = [
    0.00025
    0.00100
    0.00500
    0.01000
    0.05000
    0.10000
];

%% Generate True Mechanical Signal
x0 = [0;0];

[t_sim,X] = ode45( ...
    @(tt,x)tissue_model(tt,x,m,c,k,F0,f_exc), ...
    t, ...
    x0);

displacement = X(:,1);
velocity = X(:,2);

force = F0.*sin(2*pi*f_exc.*t_sim);

true_acc = ...
    (force-c.*velocity-k.*displacement)./m;

true_rms = rms(true_acc);

%% Storage
numLevels = length(noise_density_levels);

error_rms = zeros(numLevels,1);
snr_db = zeros(numLevels,1);
detected_frequency = zeros(numLevels,1);

%% Frequency Analysis Settings
fs_noise = fs;

%% Noise Sweep
rng(1);

for i = 1:numLevels

    noise_density = noise_density_levels(i);

    noise_rms = noise_density*sqrt(bandwidth);

    noise = noise_rms.*randn(size(true_acc));

    measured_acc = true_acc + bias + noise;

    %% Measurement Error

    error_signal = measured_acc - true_acc;

    error_rms(i) = rms(error_signal);

    %% SNR

    snr_db(i) = 20*log10(true_rms/error_rms(i));

    %% FFT Detection

    signal_ac = measured_acc - mean(measured_acc);

    N = length(signal_ac);

    window = hann(N);

    Y = fft(signal_ac.*window);

    magnitude = abs(Y)/(N*mean(window));

    if rem(N,2) == 0
        magnitude = magnitude(1:N/2+1);
        magnitude(2:end-1) = 2*magnitude(2:end-1);
    else
        magnitude = magnitude(1:(N+1)/2);
        magnitude(2:end) = 2*magnitude(2:end);
    end

    f_axis = (0:length(magnitude)-1)'*(fs_noise/N);

    magnitude(1) = 0;

    [~,index] = max(magnitude);

    detected_frequency(i) = f_axis(index);

end

%% Display Results

fprintf('\n========================================\n');
fprintf(' DIA-TISSUE NOISE / SNR ANALYSIS\n');
fprintf('========================================\n');

fprintf('\nTrue acceleration RMS = %.6f m/s^2\n',true_rms);

fprintf('\nNoise Density\t\tError RMS\tSNR(dB)\tDetected Freq\n');
fprintf('m/s^2/sqrt(Hz)\t\tm/s^2\t\t\tHz\n');
fprintf('------------------------------------------------------------\n');

for i = 1:numLevels

    fprintf('%.6f\t\t%.6f\t%.2f\t\t%.2f\n', ...
        noise_density_levels(i), ...
        error_rms(i), ...
        snr_db(i), ...
        detected_frequency(i));

end

fprintf('============================================\n');

%% Results Folder

resultsFolder = fullfile( ...
    fileparts(mfilename('fullpath')),'results');

if ~exist(resultsFolder,'dir')
    mkdir(resultsFolder);
end

%% Figure 1 - Measurement Error vs Noise

figure;

semilogx( ...
    noise_density_levels, ...
    error_rms, ...
    'o-','LineWidth',1.5);

xlabel('Noise Density (m/s^2/sqrt(Hz))');
ylabel('Measurement Error RMS (m/s^2)');

title('DIA-TISSUE - Measurement Error vs Sensor Noise');

grid on;

saveas(gcf, ...
    fullfile(resultsFolder,'measurement_error_vs_noise.png'));

%% Figure 2 - SNR vs Noise

figure;

semilogx( ...
    noise_density_levels, ...
    snr_db, ...
    'o-','LineWidth',1.5);

xlabel('Noise Density (m/s^2/sqrt(Hz))');
ylabel('SNR (dB)');

title('DIA-TISSUE - SNR vs Sensor Noise');

grid on;

saveas(gcf, ...
    fullfile(resultsFolder,'snr_vs_noise.png'));

%% Figure 3 - Detected Frequency

figure;

semilogx( ...
    noise_density_levels, ...
    detected_frequency, ...
    'o-','LineWidth',1.5);

hold on;

yline(f_exc,'--');

xlabel('Noise Density (m/s^2/sqrt(Hz))');
ylabel('Detected Frequency (Hz)');

title('DIA-TISSUE - Detected Frequency vs Sensor Noise');

grid on;

hold off;

saveas(gcf, ...
    fullfile(resultsFolder,'detected_frequency_vs_noise.png'));