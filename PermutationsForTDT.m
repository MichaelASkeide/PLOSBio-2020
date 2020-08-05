%% Permutations for The Decoding Toolbox -- TEST FOR HPC
% Run permutation analysis of the searchlight MVPA
%
% Zahra Emami October 24, 2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fname = PermutationsForTDT(permNo, coreNo, basePath, toolPath)
%% Specifications

% Housekeeping
addpath(genpath(toolPath))

% ground truth file
GDpath = [basePath, '/res_cfg.mat']; %[basePath, '/Test/Test2Results/res_cfg.mat'];

% permutation design file
permPath = [basePath, '/designs_cfg.mat']; %[basePath, '/Test/Test2Results/res_cfg.mat'];

% save path
savePath = [basePath, '/perm/'];%[basePath, '/Test/Test2Results/perm/'];

% maskFile


%% Set max cores
% folder = [basePath, 'Jobs_', int2str(randi([1 10000],1))];
% mkdir(folder)
% cluster = parallel.cluster.Generic( 'JobStorageLocation', folder);

% % terminate existing interactive session
% delete(gcp('nocreate'))
% 
% % maxNumCompThreads(coreNo); %(threadNo); %(coreNo);
% pc = parpool(coreNo-1);
% pc.JobStorageLocation=strcat('/u/zemami/Scratch/slurmJobs/',getenv('slurmArrayID'));

%% Load ground truth
load(GDpath, 'cfg', 'final_cfg', 'passed_data', 'results');
org_cfg = cfg; % keeping the unpermuted cfg to copy parameters below

%% Load permutation file
load(permPath, 'cfg', 'designs');

%% Initialize
mask_index = results.mask_index;
ref_corr = results.corr.output;
mask_index = results.mask_index;
count_index = zeros(size(mask_index));

pThresh = length(designs)*0.05;

%% Run
% Total Time Count
t0 = datestr(now);
ind = 1:length(permNo);
% fname = cell(1,length(permNo));

delete(gcp('nocreate'))
pc = parpool(coreNo);

filePaths = {permPath,GDpath};
addAttachedFiles(pc, filePaths);

for i_perm = permNo %i_perm = 1:n_perms
    
    B = load(GDpath, 'cfg', 'final_cfg', 'passed_data', 'results');
    A = load(permPath, 'cfg', 'designs');

    tempcfg = A.cfg;

    t1 = datestr(now);
    timeDiff = diff(datetime([t0;t1]));
 
    tempcfg.design = designs{i_perm};
    tempcfg.results.filestart = ['perm' sprintf('%05d',i_perm)];
    
    tempcfg.design.function.permutation = 1;
    tempcfg.design.unbalanced_data = 'ok';
    
    % do the decoding for this permutation
%     [results, final_cfg, ~] = decoding_Z_T(tempcfg, passed_data); % run permutation
    [results, final_cfg] = decoding_Z_T(tempcfg, B.passed_data); % run permutation

    % display step and time passed
    dispv(1, 'Permutation %i/%i; Total time passed: %s ', i_perm, permNo(end),char(timeDiff))
    
    % write results
    fname = [savePath, tempcfg.results.filestart, '_data.mat']; %[cfg.results.dir, '/', tempcfg.results.filestart, '_data.mat'];
    final_cfg = rmfield(final_cfg, 'fighandles');
    if ~isdir(savePath)%~isdir(cfg.results.dir)
        mkdir(savePath)%mkdir(cfg.results.dir);
    end
    parsave(fname,results, final_cfg)
    
    close all
end

% exit