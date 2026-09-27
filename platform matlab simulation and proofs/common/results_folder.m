function folder = results_folder(expDir)
% RESULTS_FOLDER  Output folder for an experiment's figures.
%
%   folder = results_folder(expDir)
%
% Returns <suite root>/outputs/<experiment folder name>/ and creates it if
% needed. All generated PNGs go under outputs/ (git-ignored), so running the
% suite never modifies tracked files.

if isempty(expDir)
    expDir = pwd;
end
[projectRoot, expName] = fileparts(expDir);
folder = fullfile(projectRoot, 'outputs', expName);
if ~exist(folder, 'dir')
    mkdir(folder);
end
end
