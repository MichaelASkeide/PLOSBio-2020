%% Extracting variables from spreadsheet
% Ensure the ordering matches the order of the files in the image folder
%
% Zahra Emami December 5, 2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Specifications

% input paths
filePaths = @(g) ['/data/p_00614/VOLEX/MATH/Data/',g,'/behav/behav.csv'];
scanPaths =  @(g) ['/data/p_00614/VOLEX/MATH/Data/',g,'/img/'];

groups = {'A', 'B'};

covarsInd = [2:7];
Covars = {'sex', 'handedness', 'age', 'total_intracranial_volume', ...
    'maternal_education', 'nonverbal_IQ'};

regressInd = [8 9 10];
RegressVars = {'math_tot', 'math_visp', 'math_arith'};

% output paths
CovarSavePath = @(g,name) ['/data/p_00614/VOLEX/MATH/Data/Covars_',name,'_',g,'.mat'];
RegressionSavePath = @(g,name) ['/data/p_00614/VOLEX/MATH/Data/Regress_',name,'_',g,'.mat'];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% get paths and data
A = cell(1,length(groups));
for gg = 1:length(groups)
    
    if strcmpi(groups{gg}, 'A')
        formatSpec ='%s%s%s%s%s%s%s%s%s%s%s%s%s%s'; % corresponds to pseudosorted .csv file format
    else
        formatSpec ='%s%s%s%s%s%s%s%s%s%s';
    end
    
    fileID = fopen(filePaths(groups{gg}),'r');
    A{gg} = textscan(fileID,formatSpec, 'Delimiter',',\n');

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Order based on files in scan folder
% Compare IDs for each group with the spreadsheet
%%%%%% This is just a check so far, Z integrate this if necessary

% initialize
GroupID = cell(1,length(groups));
newV_ID = cell(1,length(groups));
newGroupID = cell(1,length(groups));
Correct = zeros(1,length(groups));
fileOrder = cell(1,length(groups));

for gg = 1:length(groups)
    listing = dir(scanPaths(groups{gg}));
    
    % clean up
    listing = listing(~cellfun('isempty', {listing.name})); % empty entries
    listing = listing(cellfun(@(x) ~contains(x,'.hdr'), {listing.name})); % duplicates
    listing = listing(cellfun(@(x) ~contains(x,'..'), {listing.name})); % folders
    listing = listing(cellfun(@(x) ~strcmpi(x,'.'), {listing.name})); % folders
    
    % Reorganize struct 2 cell
    temp = struct2cell(listing);
    temp = temp(1,:)'; % just take names
    
    GroupID{gg} = cellfun(@(x) strrep(strrep(x,'gmv',''),'.img',''), temp, 'un',0); % remove unnecessary identifiers
    fileOrder{gg} = A{gg}{1}(2:end);

    % Check against txt ID
    if ~isempty(find(contains(fileOrder{gg}, GroupID{gg})==0, 1)) || ~isempty(find(contains(GroupID{gg},fileOrder{gg})==0, 1))
       if ~isempty(find(contains(fileOrder{gg}, GroupID{gg})==0, 1))
        warning('Scan folder missing Participant %s\nRemoving participant from behavioural ID', fileOrder{gg}{find(contains(fileOrder, GroupID{gg})==0, 1)});
        newV_ID{gg} = fileOrder{gg}(~contains(fileOrder{gg},GroupID{gg})==0);
        newGroupID{gg} = GroupID;
       else
        warning('Behavioural file missing Participant %s -- Removing participant from folder ID\n', GroupID{gg}{contains(GroupID{gg},fileOrder{gg})==0});
        newGroupID{gg} = GroupID{gg}(~contains(GroupID{gg},fileOrder{gg})==0);
        newV_ID{gg} = fileOrder{gg};
       end
    else   
       newGroupID{gg} = GroupID{gg};
       newV_ID{gg} = fileOrder{gg};
    end

    % ensure remaining sort is correct
    index = cell2mat(cellfun(@(x) find(contains(newV_ID{gg}, x)), newGroupID{gg}, 'un', 0));
    Correct(gg) = find((index == (1:length(index))'),1); % to check for order, returns 1 if order is appropriate

end
%%%%%% This is just a check so far, Z integrate this if necessary
%% Extract variables of interest

check_covar = cell(1,length(groups));
check_regress = cell(1,length(groups));

B = cell(1,length(groups));
C = cell(1,length(groups));
for gg = 1:length(groups)
    check_covar{gg} = cellfun(@(x) x{1}, A{gg}(covarsInd), 'un',0);
    check_regress{gg} = cellfun(@(x) x{1}, A{gg}(regressInd), 'un',0);
    
    temp = A{gg}(covarsInd);
    temp = horzcat(temp{:});
    B{gg} = temp(2:end,:);
    
    orary = A{gg}(regressInd);
    orary = horzcat(orary{:});
    C{gg} = orary(2:end,:);
    
end

%% Create variables for each covar, split into Pronto-compatible format & save

Covariates = cell2struct(cell(1,length(Covars)), Covars, 2);

for cv = 1:length(Covars)
    Vars = cell(1,length(groups));
    for gg = 1:length(groups)
        Vars{gg} = cell2mat(cellfun(@(x) str2double(x), (B{gg}(:,cv)), 'un',0));
    
        covariate = [];
        if strcmpi(Covars(cv),'gender') % categorical
            covariate(:,1) = Vars{gg}==1;
            covariate(:,2) = Vars{gg}==0;
        else
            covariate(:,1) = Vars{gg};
        end
        save(CovarSavePath(groups{gg},Covars{cv}), 'covariate', 'GroupID', 'fileOrder');
    end
        Covariates.(Covars{cv}) = Vars;
end

%% Create variables for each regressor, split into Pronto-compatible format & save

Regressors = cell2struct(cell(1,length(RegressVars)), RegressVars, 2);

for rg = 1:length(RegressVars)
    Vars = cell(1,length(groups));
    for gg = 1:length(groups)
        Vars{gg} = cell2mat(cellfun(@(x) str2double(x), (C{gg}(:,rg)), 'un',0));
    
        rt_subj = Vars{gg};
        save(RegressionSavePath(groups{gg},RegressVars{rg}), 'rt_subj', 'GroupID', 'fileOrder');
    end
        Regressors.(RegressVars{rg}) = Vars;
end

%% Combined MAT file for covariates
for gg = 1:length(groups)

R = [];
temp = [];

    count = 1;
    for cv = 1:length(Covars)
        if strcmpi(Covars(cv),'gender')
            temp = cell2mat(cellfun(@(x) str2double(x), (B{gg}(:,cv)), 'un',0));
            
            R(:,count) = temp==1;
            R(:,count+1) = temp==0;
            
            count = count+1;
        else
        R(:,cv+count-1) = cell2mat(cellfun(@(x) str2double(x), (B{gg}(:,cv)), 'un',0));
        end
    end
    save(CovarSavePath(groups{gg},'Combined'), 'R', 'GroupID', 'fileOrder');
end

%% Combined MAT file for regressors
for gg = 1:length(groups)
  rt_subj = zeros(length(C{gg}),length(RegressVars));

    for rg = 1:length(RegressVars)
        rt_subj(:,rg) = cell2mat(cellfun(@(x) str2double(x), (C{gg}(:,rg)), 'un',0));
    end
    save(RegressionSavePath(groups{gg},'Combined'), 'rt_subj', 'GroupID', 'fileOrder');
end