%% DIA-TISSUE
% Experiment 2: Effect of Tissue Stiffness
% SIMULATION ASSUMPTION - NOT A CLINICAL VALUE
% Models A, B and C represent controlled stiffness variations only.
clear;
clc;
close all;
%% Project Path
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot,'common'));
%% Load Parameters
simulation_parameters;
%% Define Models
k_values = [k_A k_B k_C];
c_values = [c_A c_B c_C];
model_names = {
    'Model A - Compliant'
    'Model B - Moderately Increased Stiffness'
    'Model C - Substantially Increased Stiffness'
};
%% Initial Conditions
x0 = [0;0];
%% Common Time Vector
tspan = t;
%% Storage
numModels = 3;
displacement_all = zeros(length(t),numModels);
velocity_all = zeros(length(t),numModels);
acceleration_all = zeros(length(t),numModels);
peak_acc = zeros(numModels,1);
rms_acc = zeros(numModels,1);
%% Input Force
force = F0.*sin(2*pi*f_exc.*t);
%% Simulate All Three Models
for i = 1:numModels
    k = k_values(i);
    c = c_values(i);
    [t_sim,X] = ode45(@(tt,x) tissue_model(tt,x,m,c,k,F0,f_exc),tspan,x0);
    displacement = X(:,1);
    velocity = X(:,2);
    acceleration = (force-c.*velocity-k.*displacement)./m;
    displacement_all(:,i) = displacement;
    velocity_all(:,i) = velocity;
    acceleration_all(:,i) = acceleration;
    peak_acc(i) = max(abs(acceleration));
    rms_acc(i) = rms(acceleration);
end
%% Theoretical Natural Frequencies
fn = (1/(2*pi)).*sqrt(k_values./m);
%% Display Results
fprintf('\n==============================================\n');
fprintf(' DIA-TISSUE STIFFNESS COMPARISON\n');
fprintf(' SIMULATION ASSUMPTIONS - NOT CLINICAL VALUES\n');
fprintf('==============================================\n');
for i = 1:numModels
    fprintf('\n%s\n',model_names{i});
    fprintf('Stiffness = %.1f N/m\n',k_values(i));
    fprintf('Natural frequency = %.2f Hz\n',fn(i));
    fprintf('Peak acceleration = %.4f m/s^2\n',peak_acc(i));
    fprintf('RMS acceleration = %.4f m/s^2\n',rms_acc(i));
end
fprintf('\nExcitation frequency = %.2f Hz\n',f_exc);
fprintf('==============================================\n');
%% Results Folder
resultsFolder = fullfile(fileparts(mfilename('fullpath')),'results');
if ~exist(resultsFolder,'dir')
    mkdir(resultsFolder);
end
%% Figure 1 - Displacement Comparison
figure;
plot(t,displacement_all(:,1),'LineWidth',1.2);
hold on;
plot(t,displacement_all(:,2),'LineWidth',1.2);
plot(t,displacement_all(:,3),'LineWidth',1.2);
xlabel('Time (s)');
ylabel('Displacement (m)');
title('DIA-TISSUE - Effect of Stiffness on Displacement');
legend(model_names,'Location','best');
grid on;
saveas(gcf,fullfile(resultsFolder,'stiffness_displacement.png'));
%% Figure 2 - Acceleration Comparison
figure;
plot(t,acceleration_all(:,1),'LineWidth',1.2);
hold on;
plot(t,acceleration_all(:,2),'LineWidth',1.2);
plot(t,acceleration_all(:,3),'LineWidth',1.2);
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');
title('DIA-TISSUE - Effect of Stiffness on Acceleration');
legend(model_names,'Location','best');
grid on;
saveas(gcf,fullfile(resultsFolder,'stiffness_acceleration.png'));
%% Figure 3 - Natural Frequency Comparison
figure;
bar(fn);
set(gca,'XTick',1:3,'XTickLabel',{'Model A','Model B','Model C'});
ylabel('Natural Frequency (Hz)');
title('DIA-TISSUE - Theoretical Resonance Shift');
grid on;
saveas(gcf,fullfile(resultsFolder,'natural_frequency_comparison.png'));
%% Figure 4 - RMS Acceleration Comparison
figure;
bar(rms_acc);
set(gca,'XTick',1:3,'XTickLabel',{'Model A','Model B','Model C'});
ylabel('RMS Acceleration (m/s^2)');
title('DIA-TISSUE - RMS Acceleration Comparison');
grid on;
saveas(gcf,fullfile(resultsFolder,'rms_acceleration_comparison.png'));