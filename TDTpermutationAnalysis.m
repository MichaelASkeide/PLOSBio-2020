%% Main calling script for calculating statistic
% after running permutation analysis of The Decoding Toolbox (on HPC)
%
% Zahra Emami Nov 10, 2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Specifications
clear

addpath(genpath('/data/p_00614/VOLEX/ABCD_ZV/Toolbox/decoding_toolbox_v3.997_Z/'));

% Number of Permutations
n_perms = 10000;%100;

% Load the results output
basePath = '/data/p_00614/VOLEX/MATH/Results/TheDecodingToolbox/SeparateMasks/Searchlight/Radius2/GroupA_math_arith_CR/'; %'/data/p_00614/VOLEX/ABCD_ZV/Data/Final/GroupA_reading_CR/'; %cfg.results.dir;
permPath = @(p) [basePath, '/perm/perm', p, '_data.mat'];

Q = load([basePath, '/res_cfg.mat']);
origQ = Q.results.corr.output;
origQnorm = Q.results.zcorr.output;
%% Check available files
[missingP, pNo] = PermCheck(n_perms,basePath);
if ~isempty(missingP)
    fprintf('%d permutation(s) are missing from the total %d\n', numel(missingP), n_perms)
else
    fprintf('%d permutations are included in the analysis\n', n_perms);
end
%% load the permutations
pNoStr = cell(1,numel(pNo));
pNoStr(:) = {repmat(num2str(0),1,5)};

permQ = zeros(length(origQ),numel(pNo));
permQnorm = zeros(length(origQ),numel(pNo));

% set(0,'DefaultFigureVisible','on');
parfor i = 1:numel(pNo)

pNoStr{i}(end-length(num2str(pNo(i)))+1:end) = num2str(pNo(i));

P = load(permPath(pNoStr{i}));

permQ(:,i) = P.x.corr.output;    
permQnorm(:,i) = P.x.zcorr.output; 

end

% check this function for later
p = stats_permutation(origQ,permQ,'both');
pnorm = stats_permutation(origQnorm,permQnorm,'both');
% p = stats_permutation(n_correct,reference,tail)

%If you have permutation maps from multiple subjects, see prevalence_inference.m')
disp('Permutation analyses finished')

%% Write image (ultimately, this can be for the p-values)
% I need cfg and results from permutation
cfg = Q.cfg;
cfg.results.write = 1;
cfg.results.output = {'ensemble_corr'};
cfg.results.resultsname = {'res_corr_perm_p'};
cfg.results.setwise = 0;
cfg.datainfo = Q.results.datainfo;
if ~strcmpi(cfg.results.dir, basePath)
    warning('File will save in different folder as original results')
    cfg.results.dir = basePath; % make sure
end
cfg.design.function = 'permZ';

% temp
P = load(permPath(pNoStr{1}));

results = P.x;
results = rmfield(results,'corr');
results = rmfield(results,'zcorr');
results.ensemble_corr.output = p; %results.corr.output;
results.ensemble_zcorr.output = pnorm;
results.mask_index = Q.results.mask_index;

decoding_write_results(cfg,results)