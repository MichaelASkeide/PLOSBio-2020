%% Prepare cfg for The Decoding Toolbox, permutations
% To be run through local server, for output to be used for HPC
% Zahra Emami October 24, 2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [cfg, designs] = PrepareTDTpermutations(basePath)%PrepareTDTpermutations(cfg)

%% Load file
% ground truth file
GDpath = [basePath, '/res_cfg.mat'];
load(GDpath, 'cfg', 'final_cfg', 'passed_data', 'results');

% Number of Permutations
n_perms = 10000;

% To reduce number of permutations by selecting only subset of searchlights
% that can be possibly significant
sub = 1;

%% Create permutation design

org_cfg = cfg; % keeping the unpermuted cfg to copy parameters below

%%% Create cfg with permuted sets
cfg = org_cfg; % initialize new cfg like the original
cfg = rmfield(cfg,'design'); % this is needed if you previously used cfg.
cfg.design.function = org_cfg.design.function;
cfg.results.dir = fullfile(basePath, 'perm'); % change directory
cfg.results.overwrite = 1; % should not overwrite results (change if you whish to do so)

combine = 0;   % see make_design_permutations how you can run all analysis in one go, might be faster but takes more memory
% If all data are exchangeable, a full permutation test can be 
% run setting cfg.permute.exchangeable = 1;
designs = make_design_permutation(cfg,n_perms,combine);

%%% Run all permutations in a loop
% With small tricks to make it run faster (reusing design figure, loading 
% data once using passed_data), renaming the design figure, and to display
% the current permutation number in the title of the design figure)

% Run only permutations that can become significant
% Example: You have 10000 permutations and a p-value of 0.05. 
% Then as soon as 500 permutations exceed the reference, the result 
% can no longer become significant and you can stop calculating those searchlights.
cfg.subsetdesign = sub;

cfg.results.write = 0;

save([basePath, '/designs_cfg.mat'], 'cfg', 'designs');
