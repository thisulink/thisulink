%% DIA-TISSUE
% Experiment 1: Baseline Mechanical Response
% SIMULATION ASSUMPTIONS - NOT CLINICAL

clear;
clc;
close all;

%% Project Path
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot,'common'));

%% Load Parameters
simulation_parameters;

%% Model A Parameters
m_model = m;
k_model = k_A;
c_model = c_A;

%% Initial Conditions
x0 = [0;0];

%% Mechanical Simulation
[t_sim,X] = ode45(@(tt,x) tissue_model(tt,x,m_model,c_model,k_model,F0,f_exc),t,x0);

%% Extract States
displacement = X(:,1);
velocity = X(:,2);

%% Applied Force
force = F0*sin(2*pi*f_exc*t_sim);

%% Acceleration
acceleration = (force-c_model*velocity-k_model*displacement)/m_model;

%% Peak and RMS Values
peak_displacement = max(abs(displacement));
rms_displacement = rms(displacement);

peak_velocity = max(abs(velocity));
rms_velocity = rms(velocity);

peak_acceleration = max(abs(acceleration));
rms_acceleration = rms(acceleration);

%% Display Results
fprintf('\n========================================\n');
fprintf(' DIA-TISSUE BASELINE MECHANICAL RESPONSE\n');
fprintf('========================================\n');

fprintf('\nMODEL A - COMPLIANT\n');

fprintf('Mass              = %.4f kg\n',m_model);
fprintf('Stiffness         = %.2f N/m\n',k_model);
fprintf('Damping           = %.2f N*s/m\n',c_model);
fprintf('Excitation        = %.2f Hz\n',f_exc);
fprintf('Force amplitude   = %.3f N\n',F0);

fprintf('\nRESULTS\n');

fprintf('Peak displacement  = %.6e m\n',peak_displacement);
fprintf('RMS displacement   = %.6e m\n',rms_displacement);

fprintf('Peak velocity      = %.6e m/s\n',peak_velocity);
fprintf('RMS velocity       = %.6e m/s\n',rms_velocity);

fprintf('Peak acceleration  = %.4f m/s^2\n',peak_acceleration);
fprintf('RMS acceleration   = %.4f m/s^2\n',rms_acceleration);

fprintf('========================================\n');

%% Results Folder
resultsFolder = fullfile(fileparts(mfilename('fullpath')),'results');

if ~exist(resultsFolder,'dir')
    mkdir(resultsFolder);
end

%% Graph 1 - Applied Force
figure;

plot(t_sim,force,'LineWidth',1.2);

xlabel('Time (s)');
ylabel('Force (N)');

title('DIA-TISSUE - Applied Excitation');

grid on;

saveas(gcf,fullfile(resultsFolder,'baseline_force.png'));

%% Graph 2 - Displacement
figure;

plot(t_sim,displacement,'LineWidth',1.2);

xlabel('Time (s)');
ylabel('Displacement (m)');

title('DIA-TISSUE - Baseline Displacement');

grid on;

saveas(gcf,fullfile(resultsFolder,'baseline_displacement.png'));

%% Graph 3 - Velocity
figure;

plot(t_sim,velocity,'LineWidth',1.2);

xlabel('Time (s)');
ylabel('Velocity (m/s)');

title('DIA-TISSUE - Baseline Velocity');

grid on;

saveas(gcf,fullfile(resultsFolder,'baseline_velocity.png'));

%% Graph 4 - Acceleration
figure;

plot(t_sim,acceleration,'LineWidth',1.2);

xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');

title('DIA-TISSUE - Baseline Acceleration');

grid on;

saveas(gcf,fullfile(resultsFolder,'baseline_acceleration.png'));