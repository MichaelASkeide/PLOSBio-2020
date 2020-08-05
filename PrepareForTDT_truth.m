%% Prepare for The Decoding Toolbox
% set up cfg variable 
% Run searchlight analysis as ground truth
%
% Zahra Emami October 24, 2019 (last modified November 18, 2019)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% HouseKeeping
clear;close; %clc;

addpath(genpath('/data/p_00614/VOLEX/ABCD_ZV/Toolbox/decoding_toolbox_v3.997_Z'))
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Specifications

groups = {'A','B'}; %{'A', 'B'}; %{'A'};
type = {'math_tot', 'math_visp', 'math_arith'}; 

% BasePath
basePath = '/data/p_00614/VOLEX/MATH';

% Image file path
baseDir = @(g) [basePath, '/Data/', g,'/img/'];

% Behav regressor vars file path
regPath = @(g,t) [basePath, '/Data/Regress_',t,'_',g, '.mat'];

% Confound var file path
conPath = @(g) [basePath, '/Data/Covars_Combined_',g, '.mat'];

% mask file path
% maskPath = [basePath, '/Data/Mask1_corr.nii'];
maskPath{1} = '/data/p_00614/VOLEX/MATH/Data/A/mask/ips437.nii';
maskPath{2} = '/data/p_00614/VOLEX/MATH/Data/B/mask/ips304.nii';

% output path
outPath = @(g,t) [basePath,'/Results/TheDecodingToolbox/SeparateMasks/Searchlight/Radius4/Group', groups{g}, '_', type{t}, '_CR'];

% set core number (this should be the max number of available CPUs on the
% machine)
coreNo = []; %24;   % leave blank to use default

%% Get data file names

% initialize
scanPaths = cell(1,length(groups));
Reg = cell(length(groups),length(type));
Conf = cell(length(groups),1);

for gg = 1:length(groups)
    
    % confounds
    temp = load(conPath(groups{gg}));
    Conf{gg} = temp.R;
    
    for tt = 1:length(type)
        % regressors
        temp = load(regPath(groups{gg},type{tt}));
        Reg{gg,tt} = temp.rt_subj;
        
    end
    
    % scan paths
    listing = dir(baseDir(groups{gg}));
    
    % clean up
    listing = listing(~cellfun('isempty', {listing.name})); % empty entries
    listing = listing(cellfun(@(x) ~contains(x,'.hdr'), {listing.name})); % duplicates
    listing = listing(cellfun(@(x) ~contains(x,'..'), {listing.name})); % folders
    listing = listing(cellfun(@(x) ~strcmpi(x,'.'), {listing.name})); % folders
    
    % index of listings to include (based on txt file)
    scanID = temp.GroupID{gg};
    ID = temp.fileOrder{gg};
    listing = listing(~contains(scanID,ID)==0);
    
    % scan file paths
    scanPaths{gg} = arrayfun(@(x) [listing(x).folder, '/', listing(x).name], 1:length(listing), 'un',0);
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set of cfg variable and run TDT for each analysis

% For each group
for gg = 1:length(groups)
    
    for tt = 1:length(type)
        
    % arrange the response and predictor variables
    regressVars = Reg{gg,tt}';%vertcat(Reg{:})';
    particPaths = horzcat(scanPaths{gg});
    
    % check to see if any missing (NaN) data and remove
    regressVars = regressVars(~isnan(regressVars));
    particPaths = particPaths(~isnan(regressVars));   
    
    % Set defaults
    cfg = decoding_defaults;
    
    % hack for quicker SVR (suggested by Martin) is to use a regularization
    % parameter of C = 0.1 instead of 1
    cfg.decoding.train.regression.model_parameters = '-s 4 -t 0 -c 0.1 -n 0.5 -b 0 -q';
    
    % Set the analysis that should be performed (default is 'searchlight')
    cfg.analysis = 'searchlight'; %'roi'; %'searchlight';
    
    % Searchlight specifications
    cfg.searchlight.unit = 'mm';
    cfg.searchlight.radius = 4; % this will yield a searchlight radius of 4mm. % Kriegeskorte et al. (2006) [reviewed in Etzel et al 2014] showed that detection did not require a close match between the size of the searchlight and the informative area: a 4 mm radius consistently performed well
    cfg.searchlight.spherical = 1;
    
    % Set the output directory where data will be saved, e.g. 'c:\exp\results\buttonpress'
    cfg.results.dir = outPath;
    % other results specs
    cfg.results.overwrite = 1; % 0 for not overwriting existing results file
    
    % Set the filename of your brain mask (or your ROI masks as cell array)
    % for searchlight or wholebrain e.g. 'c:\exp\glm\model_button\mask.img' OR
    % for ROI e.g. {'c:\exp\roi\roimaskleft.img', 'c:\exp\roi\roimaskright.img'}
    % You can also use a mask file with multiple masks inside that are
    % separated by different integer values (a "multi-mask")
    cfg.files.mask = {maskPath{gg}}; %{maskPathgg}; %1xm cell with filename(s) of mask(s) as strings
    
    % Set the following field:
    % Full path to file names (1xn cell array) (e.g.
    % {'c:\exp\glm\model_button\im1.nii', 'c:\exp\glm\model_button\im2.nii', ... }
    cfg.files.name = particPaths';
    % and the other two fields if you use a make_design function (e.g. make_design_cv)
    %
    % (1) a nx1 vector to indicate what data you want to keep together for
    % cross-validation (typically runs, so enter run numbers)
    cfg.files.chunk =(1:length(regressVars))';
    cfg.permute.exchangeable = 1;
    %
    % (2) any numbers as class labels, normally we use 1 and -1. Each file gets a
    % label number (i.e. a nx1 vector)
    cfg.files.label = regressVars'; %[Ar;Br]; %ones(length(particPaths),1);
    
    % cfg.design.function.name = 'make_design_cv';
    % cfg.permute.exchangeable = 1;
    % cfg.design = make_design_cv(cfg);
    
    % replace design with your own 10-fold CV
    cfg.files.fold = 10;
    % cfg.design.set = ones(1,cvFold);
    cfg.design = make_design_cvfold(cfg);
    
    cfg.design.unbalanced_data = 'ok';
    
    % Decide whether you want to see the searchlight/ROI/... during decoding
    cfg.plot_selected_voxels = 0;
    
    % Determine the method
    cfg.decoding.method = 'regression';
    
    % Define what you want in the output results variable
    cfg.results.output = {'corr', 'R2'};
    
    % plotting / results displayed
    cfg.plot_design = 2;
    cfg.results.write = 0;
    
    % for confounds
    cfg.files.confounds = Conf{gg};%Conf{:};
    cfg.confound = 1;
    
    % open parallel pool for the decoding using specified number of cores
    if coreNo
        parpool(coreNo)
    end
    
    % Run decoding
    [results, final_cfg, passed_data] =  decoding_Z_T(cfg);
    
    finalFig = final_cfg.fighandles.plot_design;
    final_cfg = rmfield(final_cfg, 'fighandles');
    
    % save results
    if ~exist(outPath(gg,tt), 'file')
        mkdir(outPath(gg,tt))
    end
    save([outPath(gg,tt), '/res_cfg_withR2.mat'], 'cfg','final_cfg', 'passed_data', 'results');
    savefig(finalFig,[outPath(gg,tt), '/res.fig']);

    %% Prepare permutation designs
%     PrepareTDTpermutations(outPath(gg,tt))
    
    end
end
