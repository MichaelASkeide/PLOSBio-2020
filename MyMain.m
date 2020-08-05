%% Main calling script for running permutation analysis of
% The Decoding Toolbox on HPC; to be called through SLURM script 
% will be called by "uk_slurm_array_job_MA.sh" (Script #3)
% 
% Zahra Emami Nov 10, 2019
% adapted by Ulrike Kuhl, June 2020

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function MyMain(varargin)

v.permNo = 1;
v.coreNo = 24;
v.basePath = '/data/p_00614/VOLEX/ABCD_ZV/Results/TheDecodingToolbox/GroupB_vocabulary_CR';
v.toolPath = '/data/p_00614/VOLEX/ABCD_ZV/Toolbox/decoding_toolbox_v3.997_Z/';
v.permsPerNode = 50;

known_vars = fieldnames(v);
if mod(nargin,2) ~= 0
    error('Expecting an even number of arguments');
end
for idx = 1 : 2 : nargin-1
    if ~ismember(varargin{idx}, known_vars)
        error('Argument "%s" is not a variable name I know', varargin{idx});
    end
    
    if ~strcmpi(varargin{idx}, 'basePath') && ~strcmpi(varargin{idx}, 'toolPath')
        val = str2double(varargin{idx+1});
    else
        val = varargin{idx+1};
    end
    
    if isnan(val)
        error('Value "%s" for variable "%s" is not a numeric scalar', varargin{idx+1}, varargin{idx});
    end
    v.(varargin{idx}) = val;
end

% specify the total number of tasks
permutations = 1:10000;
permsPerNode = v.permsPerNode; %50; % specify how to distribute tasks across nodes, expects 200 nodes

% this is the default distribtion organization given the task distrib across nodes
% and the permutations
n = numel(permutations);
groupsNode = reshape(permutations, [permsPerNode n/permsPerNode])'; % row is node, column is permutation

%% For skipping already completed permutations
savePath = [v.basePath, '/perm/'];
listing = dir(savePath);
listing = listing(cellfun(@(x) ~contains(x,'..'), {listing.name})); % folders
listing = listing(cellfun(@(x) ~strcmpi(x,'.'), {listing.name})); % folders

temp = struct2cell(listing);
temp = temp(1,:)'; % just take names
fileNo = cell2mat(cellfun(@(x) str2double(strrep(strrep(char(x),'perm',''),'_data.mat','')), temp, 'un',0));

ind = cell2mat(arrayfun(@(x) find(permutations==fileNo(x)), 1:length(fileNo), 'un', 0));
permutations(ind) = NaN;
groupsNode = reshape(permutations, [permsPerNode n/permsPerNode])'; % row is node, column is permutation
%%
% 
% % if the available nodes are not consistent with how the distribution was
% % organized, specify a subset to run (for testing purposes)
% if nodes ~= size(groupsNode,1)
%     selectStart = v.permNo;
%     groupsNode = groupsNode(selectStart:selectStart+nodes-1,:);
% end
v.permNo = groupsNode(v.permNo,:);
v.permNo = v.permNo(~isnan(v.permNo));

% this will send through an array for permutations to be run in sequence
if ~isempty(v.permNo)
    sprintf('Permutations: %s,\nCores: %d\nData Path: %s\nToolbox: %s', num2str(v.permNo), v.coreNo, v.basePath, v.toolPath)
    PermutationsForTDT(v.permNo, v.coreNo, v.basePath, v.toolPath);
end

% save([v.basePath, 'results_', num2str(inputInd),'.mat'], 'results');                  % Display the results  