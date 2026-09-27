%% =========================================================================
%% THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM - MASTER SIMULATION RUNNER
%% =========================================================================
% Project: THISULINK - Integrated Dual-Modality Frontline Diabetic Triage
% Hardware Subsystem: Plantar Biomechanical Shear Wave Elastography (SWE) Platform
%
% Runs all 12 simulation experiments one after another.
%   * Each experiment runs in its own function workspace
%     (common/run_experiment_isolated.m), so a script can never wipe this
%     runner's loop variables, and the path / current folder are restored
%     after every experiment.
%   * A failing experiment is reported and the suite continues.
%   * Figures are written to outputs/<experiment>/ and the console log to
%     outputs/master_run_log.txt. A PASS/FAIL table is printed at the end.
%
% Works in MATLAB (R2016b+) and GNU Octave (tested with 11.3):
%   matlab -batch "master_run_all"
%   octave --no-gui --eval "master_run_all"      (use octave-gui.exe/qt on
%                                                 Windows for PNG export)
%
% All results are SIMULATIONS with modelled/synthetic data. They are not
% bench measurements and not clinical evidence.
% =========================================================================

masterStart = tic;
masterRoot = fileparts(mfilename('fullpath'));
if isempty(masterRoot)
    masterRoot = pwd;
end
addpath(fullfile(masterRoot, 'common'));

masterOutDir = fullfile(masterRoot, 'outputs');
if ~exist(masterOutDir, 'dir')
    mkdir(masterOutDir);
end
masterLog = fullfile(masterOutDir, 'master_run_log.txt');
if exist(masterLog, 'file')
    delete(masterLog);
end
diary(masterLog);

% Render figures off-screen: they are saved to PNG files anyway.
masterOldFigVis = get(0, 'DefaultFigureVisible');
set(0, 'DefaultFigureVisible', 'off');
% Save every figure at 1200 x 750 px (8 x 5 in at 150 dpi) so long titles and
% legends are not clipped; restored after the run.
masterOldPaper = {get(0, 'DefaultFigurePaperUnits'), get(0, 'DefaultFigurePaperPositionMode'), ...
                  get(0, 'DefaultFigurePaperPosition')};
set(0, 'DefaultFigurePaperUnits', 'inches', 'DefaultFigurePaperPositionMode', 'manual', ...
       'DefaultFigurePaperPosition', [0 0 8 5]);
close all;

fprintf('\n');
fprintf('================================================================================\n');
fprintf('       THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM - SIMULATION SUITE          \n');
fprintf('       (simulation study - modelled parameters and synthetic data only)        \n');
fprintf('================================================================================\n');
fprintf('Start Time : %s\n', datestr(now));
fprintf('Directory  : %s\n', masterRoot);
fprintf('Outputs    : %s\n', masterOutDir);
fprintf('================================================================================\n\n');

masterExperiments = {
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

masterN = size(masterExperiments, 1);
masterResults = cell(masterN, 1);

for masterIdx = 1:masterN
    masterFolder = masterExperiments{masterIdx, 1};
    masterScript = masterExperiments{masterIdx, 2};
    fprintf('>>> Running Experiment %02d/%02d: %s ...\n', masterIdx, masterN, masterFolder);

    masterScriptFile = fullfile(masterRoot, masterFolder, [masterScript '.m']);
    if ~exist(masterScriptFile, 'file')
        r.ok = false;
        r.message = sprintf('Script not found: %s', masterScriptFile);
        r.where = '';
        r.seconds = 0;
    else
        r = run_experiment_isolated(fullfile(masterRoot, masterFolder), masterScript);
    end
    masterResults{masterIdx} = r;

    % Figures were already saved by the script; free them before the next run.
    close all;

    if r.ok
        fprintf('    [PASS] Finished in %.2f seconds.\n\n', r.seconds);
    else
        fprintf('    [FAIL] %s\n', r.message);
        if ~isempty(r.where)
            fprintf('           at %s\n', r.where);
        end
        fprintf('\n');
    end
end

masterTotal = toc(masterStart);
set(0, 'DefaultFigureVisible', masterOldFigVis);
set(0, 'DefaultFigurePaperUnits', masterOldPaper{1}, 'DefaultFigurePaperPositionMode', masterOldPaper{2}, ...
       'DefaultFigurePaperPosition', masterOldPaper{3});

%% Master Summary Table
masterPassed = 0;
fprintf('\n================================================================================\n');
fprintf('                           MASTER SIMULATION SUMMARY                            \n');
fprintf('================================================================================\n');
fprintf('%-4s %-44s %-6s %9s\n', 'Exp', 'Module', 'Result', 'Time (s)');
fprintf('--------------------------------------------------------------------------------\n');
for masterIdx = 1:masterN
    r = masterResults{masterIdx};
    if r.ok
        status = 'PASS';
        masterPassed = masterPassed + 1;
    else
        status = 'FAIL';
    end
    fprintf('%02d   %-44s %-6s %9.2f\n', masterIdx, masterExperiments{masterIdx, 1}, status, r.seconds);
    if ~r.ok
        fprintf('       -> %s\n', r.message);
    end
end
fprintf('--------------------------------------------------------------------------------\n');
fprintf('Passed: %d / %d    Total time: %.2f s\n', masterPassed, masterN, masterTotal);
fprintf('Figures: %s\n', masterOutDir);
fprintf('================================================================================\n\n');
diary off;
