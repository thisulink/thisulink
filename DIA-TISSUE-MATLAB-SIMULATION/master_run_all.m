%% THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM - MASTER SIMULATION RUNNER
% SIH 2026 Grand Finale - THISULINK Diagnostic Verification

clear;
clc;
close all;

masterStart = tic;
rootDir = fileparts(mfilename('fullpath'));
addpath(fullfile(rootDir, 'common'));

fprintf('\n================================================================================\n');
fprintf('       THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM - SIMULATION SUITE          \n');
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

for idx = 1:numExperiments
    expFolder = experiments{idx, 1};
    expScript = experiments{idx, 2};
    expPath = fullfile(rootDir, expFolder);
    
    fprintf('>>> Running Experiment %02d/%02d: %s ...\n', idx, numExperiments, expFolder);
    try
        oldDir = cd(expPath);
        run(expScript);
        cd(oldDir);
        results_status(idx) = "PASSED";
        fprintf('    [SUCCESS]\n\n');
    catch ME
        cd(oldDir);
        results_status(idx) = "FAILED";
        fprintf('    [ERROR]: %s\n\n', ME.message);
    end
end

fprintf('\nTotal Experiments Passed: %d / %d\n', sum(results_status == "PASSED"), numExperiments);
