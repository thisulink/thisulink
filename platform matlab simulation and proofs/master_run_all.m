%% =========================================================================
%% THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM - MASTER SIMULATION RUNNER
%% =========================================================================
% Project: THISULINK - Integrated Dual-Modality Frontline Diabetic Triage
% Hardware Subsystem: Plantar Biomechanical Shear Wave Elastography (SWE) Platform
% Reference: Smart India Hackathon (SIH) 2026 Grand Finale
%
% This master script runs all 12 validation experiments sequentially, generates
% all publication-quality engineering plots, and outputs comprehensive diagnostic
% verification metrics ready for GitHub release and finale presentation.
% =========================================================================

clear;
clc;
close all;

masterStart = tic;
rootDir = fileparts(mfilename('fullpath'));
addpath(fullfile(rootDir, 'common'));

fprintf('\n');
fprintf('================================================================================\n');
fprintf('       THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM - SIMULATION SUITE          \n');
fprintf('       Dual-Modality Frontline Diabetic Triage Engineering Verification         \n');
fprintf('================================================================================\n');
fprintf('Start Time: %s\n', datestr(now));
fprintf('Target GitHub Repository: https://github.com/thisulink/thisulink\n');
fprintf('Directory: %s\n', rootDir);
fprintf('================================================================================\n\n');

experiments = {
    '01_Baseline_Mechanical_Response',            'experiment_baseline'
    '02_Stiffness_Comparison',                    'experiment_stiffness'
    '03_Frequency_Sweep',                         'experiment_frequency_sweep'
    '04_FFT_Analysis',                            'experiment_fft'
    '05_Sensor_Simulation',                       'experiment_sensor'
    '06_Noise_SNR_Analysis',                      'experiment_noise_snr'
    '07_Contact_Force_Sensitivity',               'experiment_contact_force'
    '08_Load_Cell_Validation',                    'experiment_load_cell'
    '09_VCA_Electrical_Test',                     'experiment_vca'
    '10_Shear_Wave_Dispersion_and_Modulus',       'experiment_shear_wave'
    '11_Velcro_and_Flexure_Tremor_Suppression',   'experiment_stabilization'
    '12_Comprehensive_Triage_Scoring',            'experiment_multimodal_triage'
};

numExperiments = size(experiments, 1);
results_status = strings(numExperiments, 1);
execution_times = zeros(numExperiments, 1);

for idx = 1:numExperiments
    expFolder = experiments{idx, 1};
    expScript = experiments{idx, 2};
    expPath = fullfile(rootDir, expFolder);
    
    fprintf('>>> Running Experiment %02d/%02d: %s ...\n', idx, numExperiments, expFolder);
    t_start = tic;
    
    try
        oldDir = cd(expPath);
        run(expScript);
        cd(oldDir);
        execution_times(idx) = toc(t_start);
        results_status(idx) = "PASSED";
        fprintf('    [SUCCESS] Finished in %.2f seconds.\n\n', execution_times(idx));
    catch ME
        cd(oldDir);
        execution_times(idx) = toc(t_start);
        results_status(idx) = "FAILED";
        fprintf('    [ERROR] Experiment %02d failed: %s\n\n', idx, ME.message);
    end
end

totalTime = toc(masterStart);

%% Master Summary Table
fprintf('\n================================================================================\n');
fprintf('                           MASTER SIMULATION SUMMARY                            \n');
fprintf('================================================================================\n');
fprintf('Exp #\tModule Name\t\t\t\t\t\tStatus\tDuration\n');
fprintf('--------------------------------------------------------------------------------\n');
for idx = 1:numExperiments
    fprintf('%02d\t%-40s\t%s\t%.2f s\n', ...
        idx, experiments{idx, 1}, results_status(idx), execution_times(idx));
end
fprintf('--------------------------------------------------------------------------------\n');
fprintf('Total Simulation Execution Time: %.2f seconds (%.2f minutes)\n', totalTime, totalTime/60);
fprintf('Total Experiments Passed: %d / %d\n', sum(results_status == "PASSED"), numExperiments);
fprintf('================================================================================\n\n');
