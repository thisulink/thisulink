function result = run_experiment_isolated(expDir, scriptName)
% RUN_EXPERIMENT_ISOLATED  Run one experiment script in its own workspace.
%
%   result = run_experiment_isolated(expDir, scriptName)
%
% The script is executed inside a separate local function (execute_script),
% so anything it creates or clears (even 'clear all' variables) cannot touch
% this function or the caller (master_run_all). The search path and the
% current folder are saved before the run and restored afterwards, and any
% error is caught and returned instead of being thrown.
%
% result fields:
%   .ok       true if the script finished without error
%   .message  error message ('' on success)
%   .where    error location as text ('' on success)
%   .seconds  wall-clock run time [s]

oldPath = path;
oldDir  = pwd;
t0      = tic;

result.ok      = false;
result.message = '';
result.where   = '';

try
    execute_script(fullfile(expDir, [scriptName '.m']));
    result.ok = true;
catch err
    result.message = err.message;
    if ~isempty(err.stack)
        result.where = sprintf('%s (line %d)', err.stack(1).name, err.stack(1).line);
    end
end

path(oldPath);
cd(oldDir);
drawnow;
result.seconds = toc(t0);
end

function execute_script(scriptFile)
% Private workspace for the experiment script.
run(scriptFile);
end
