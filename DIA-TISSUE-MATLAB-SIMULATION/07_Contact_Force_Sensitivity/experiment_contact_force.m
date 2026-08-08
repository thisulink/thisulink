%% DIA-TISSUE
% Experiment 7: Contact Force Sensitivity
% SIMULATION ASSUMPTION - NOT A CLINICAL VALUE

clear;
clc;
close all;

%% Project Path
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot,'common'));

%% Load Common Parameters
simulation_parameters;

%% Contact Force Parameters
baseline_k = k_A;
target_force = 2.0;
alpha = 150.0;

contact_force = [1.0 2.0 3.0];

condition_names = {
    'Low Contact'
    'Target Contact'
    'High Contact'
};

%% Storage
effective_k = zeros(3,1);
natural_frequency = zeros(3,1);
acceleration = zeros(3,1);

%% Calculate Mechanical Response
for i = 1:3

    F_contact = contact_force(i);

    effective_k(i) = ...
        baseline_k + alpha*(F_contact-target_force);

    natural_frequency(i) = ...
        (1/(2*pi))*sqrt(effective_k(i)/m);

    %% Steady-state acceleration calculation
    w = 2*pi*f_exc;

    denominator = ...
        (effective_k(i)-m*w^2) + 1i*(c_A*w);

    displacement_amplitude = ...
        abs(F0/denominator);

    acceleration(i) = ...
        w^2*displacement_amplitude;

end

%% Display Results

fprintf('\n=============================================\n');
fprintf(' DIA-TISSUE CONTACT FORCE SENSITIVITY\n');
fprintf('=============================================\n');

fprintf('\nSIMULATION ASSUMPTION - NOT CLINICAL VALUES\n');

fprintf('\nBaseline tissue stiffness = %.1f N/m\n',baseline_k);
fprintf('Target contact force      = %.1f N\n',target_force);
fprintf('Contact sensitivity alpha = %.1f (N/m)/N\n',alpha);

fprintf('\nCondition\tForce(N)\tEffective k\tNatural Freq\tAcceleration\n');
fprintf('\t\t\t\t(N/m)\t\t(Hz)\t\t(m/s^2)\n');
fprintf('-------------------------------------------------------------------\n');

for i = 1:3

    fprintf('%s\t%.2f\t\t%.2f\t\t%.2f\t\t%.4f\n', ...
        condition_names{i}, ...
        contact_force(i), ...
        effective_k(i), ...
        natural_frequency(i), ...
        acceleration(i));

end

fprintf('=============================================\n');

%% Results Folder

resultsFolder = fullfile( ...
    fileparts(mfilename('fullpath')),'results');

if ~exist(resultsFolder,'dir')
    mkdir(resultsFolder);
end

%% Figure 1 - Contact Force vs Effective Stiffness

figure;

plot(contact_force,effective_k,'o-','LineWidth',1.5);

xlabel('Contact Force (N)');
ylabel('Effective Stiffness (N/m)');

title('DIA-TISSUE - Contact Force vs Effective Stiffness');

grid on;

saveas(gcf, ...
    fullfile(resultsFolder,'contact_force_vs_stiffness.png'));

%% Figure 2 - Contact Force vs Natural Frequency

figure;

plot(contact_force,natural_frequency,'o-','LineWidth',1.5);

xlabel('Contact Force (N)');
ylabel('Natural Frequency (Hz)');

title('DIA-TISSUE - Contact Force vs Natural Frequency');

grid on;

saveas(gcf, ...
    fullfile(resultsFolder,'contact_force_vs_natural_frequency.png'));

%% Figure 3 - Contact Force vs Acceleration

figure;

plot(contact_force,acceleration,'o-','LineWidth',1.5);

xlabel('Contact Force (N)');
ylabel('Acceleration (m/s^2)');

title('DIA-TISSUE - Contact Force vs Mechanical Response');

grid on;

saveas(gcf, ...
    fullfile(resultsFolder,'contact_force_vs_acceleration.png'));