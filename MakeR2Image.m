%% Save R2 images

groups = {'A','B'}; %{'A', 'B'}; %{'A'};
type = {'math_tot', 'math_visp', 'math_arith'}; 

% BasePath
basePath = '/data/p_00614/VOLEX/MATH';

% output path
outPath = @(g,t) [basePath,'/Results/TheDecodingToolbox/SeparateMasks/Searchlight/Radius4/Group', groups{g}, '_', type{t}, '_CR'];

%% Write image (ultimately, this can be for the p-values)
% I need cfg and results from permutation

% For each group
for gg = 1:length(groups)
    for tt = 1:length(type)
        
        inputFile = [outPath(gg,tt), '/res_cfg_withR2.mat'];
        Q = load(inputFile);
        
cfg = Q.cfg;
cfg.results.write = 1;
cfg.results.output = {'ground_corr'};
cfg.results.resultsname = {'res_corr_modelR2'};
cfg.results.setwise = 0;
cfg.datainfo = Q.results.datainfo;
if ~strcmpi(cfg.results.dir(gg,tt), outPath(gg,tt))
    warning('File will save in different folder as original results')
end
cfg.results.dir = outPath(gg,tt); % make sure

cfg.design.function = 'R2';

results = Q.results;
results.ground_corr.output = results.R2.output;%(results.corr.output).^2; %results.corr.output;
results = rmfield(results,'corr');
results = rmfield(results,'zcorr');
results.mask_index = Q.results.mask_index;

decoding_write_results(cfg,results)
    end
end