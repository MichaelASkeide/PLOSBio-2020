% Check to see if all perms are available
function [missingP, pNo] = PermCheck(n_perms,basePath)

% Find available files
savePath = [basePath, '/perm/'];
listing = dir(savePath);
listing = listing(cellfun(@(x) ~contains(x,'..'), {listing.name})); % folders
listing = listing(cellfun(@(x) ~strcmpi(x,'.'), {listing.name})); % folders

temp = struct2cell(listing);
temp = temp(1,:)'; % just take names
fileNo = cell2mat(cellfun(@(x) str2double(strrep(strrep(char(x),'perm',''),'_data.mat','')), temp, 'un',0));

t = 1:n_perms;

% find missing perms
missingP = setdiff(t,fileNo);

% return vector of available perms for analysis
availP = t(fileNo);
if numel(availP) < n_perms
    pNo = availP;
else
    pNo = t;
end