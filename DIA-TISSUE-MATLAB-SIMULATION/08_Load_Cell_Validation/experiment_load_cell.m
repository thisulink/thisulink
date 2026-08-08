%% DIA-TISSUE
% Experiment 8: Load Cell Validation
% SIMULATION ASSUMPTION - NOT A CLINICAL LIMIT

clear;
clc;
close all;

%% Project Path
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot,'common'));

%% Load Common Parameters
simulation_parameters;

%% Load Cell Parameters
lower_force_limit = 1.50;
upper_force_limit = 2.50;
load_cell_noise = 0.030;

%% Test Conditions
condition_names = {
    'Low Contact'
    'Target Contact'
    'High Contact'
};

true_force = [1.00;2.00;3.00];

%% Simulate Load Cell Measurements
rng(1);

measured_force = ...
    true_force + load_cell_noise.*randn(size(true_force));

%% Contact Validation
status = strings(3,1);

for i = 1:3

    if measured_force(i) < lower_force_limit
        status(i) = "INVALID CONTACT";
    elseif measured_force(i) > upper_force_limit
        status(i) = "EXCESSIVE CONTACT";
    else
        status(i) = "VALID SCAN";
    end

end

%% Display Results

fprintf('\n=============================================\n');
fprintf(' DIA-TISSUE LOAD CELL VALIDATION\n');
fprintf('=============================================\n');

fprintf('\nRESEARCH PARAMETERS - NOT CLINICAL LIMITS\n');

fprintf('\nLower force limit = %.2f N\n',lower_force_limit);
fprintf('Upper force limit = %.2f N\n',upper_force_limit);
fprintf('Load-cell noise   = %.3f N std\n',load_cell_noise);

fprintf('\nCondition\tTrue Force\tMean Measured\tStatus\n');
fprintf('\t\t(N)\t\t(N)\n');
fprintf('---------------------------------------------------------\n');

for i = 1:3

    fprintf('%s\t%.2f\t\t%.4f\t\t%s\n', ...
        condition_names{i}, ...
        true_force(i), ...
        measured_force(i), ...
        status(i));

end

fprintf('=============================================\n');

%% Results Folder

resultsFolder = fullfile( ...
    fileparts(mfilename('fullpath')),'results');

if ~exist(resultsFolder,'dir')
    mkdir(resultsFolder);
end

%% Figure 1 - True vs Measured Force

figure;

bar([true_force measured_force]);

xlabel('Contact Condition');
ylabel('Force (N)');

title('DIA-TISSUE - Load Cell Validation');

set(gca,'XTick',1:3);
set(gca,'XTickLabel',condition_names);

legend('True Force','Measured Force','Location','best');

grid on;

saveas(gcf, ...
    fullfile(resultsFolder,'load_cell_true_vs_measured.png'));

%% Figure 2 - Force Limits

figure;

plot(1:3,measured_force,'o-','LineWidth',1.5);

hold on;

yline(lower_force_limit,'--');
yline(upper_force_limit,'--');

xlabel('Contact Condition');
ylabel('Measured Force (N)');

title('DIA-TISSUE - Contact Force Validation Limits');

set(gca,'XTick',1:3);
set(gca,'XTickLabel',condition_names);

legend('Measured Force','Lower Limit','Upper Limit', ...
    'Location','best');

grid on;

hold off;

saveas(gcf, ...
    fullfile(resultsFolder,'load_cell_validation_limits.png'));