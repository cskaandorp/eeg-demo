function [ds] = PSR_mkCoSMoData(data, classInfo, balance)
% PSR_MKCOSMODATA Make structure with data arranged in CoSMoMVPA format.
%
% Input: 
%   data        Timelocked fieltrip dataset (obtained in PSR_loadTimelock.m)
%   classInfo   Cell with strings of properties to-be classified in (:,1) 
%               and corresponding column of data.trialinfo in (:,2) 
%   balance     Cell with strings of properties to-be balanced in (:,1) 
%               and corresponding column of data.trialinfo in (:,2) 
%
% Output:
%   ds          CoSMo dataset with to-be classified conditions
%
% Note: Here, class refers to the variable that will be classified, e.g. 
% spatial frequency (SF). The condition refers to the different 
% properties inside a class, e.g. high SF and low SF. It is assumed that 
% the different conditions important for class(x) are found in the 
% corresponding column, data.trialinfo(:,x).


%% Make CoSMo dataset
ds = cosmo_meeg_dataset(data);

%% .SA (sample attributes)      
% .chunks (assuming all trials are independent)
ntrials = size(data.trial,1);
ds.sa.chunks = (1:ntrials)';

% .targets (prepare dataset for later definition of targets)
classDef   = classInfo(:,1);
clcolumn   = cell2mat(classInfo(:,2));

for nclass = 1: numel(classDef)

    ds.sa.(classDef{nclass}) = data.trialinfo(:, clcolumn(nclass)); 
    
end
% Define .targets so cosmo_check_dataset(ds) works (will be overwritten later)
ds.sa.targets = data.trialinfo(:, clcolumn(1));

% .type (needed in PSR_mkCoSMoPartitions_BALANCE)
% create matrix with all properties that need balancing
balDef   = balance(:,1);
blcolumn = cell2mat(balance(:,2));

condMatrix = NaN(ntrials,numel(balDef));
for nbalance = 1: numel(balDef)

    condMatrix(:,nbalance) = data.trialinfo(:, blcolumn(nbalance)); 

end 

% find the unique property combinations (i.e. stim conditions)
cond = unique(condMatrix, 'row');
ds.sa.type = NaN(ntrials,1);

for ntype = 1: size(cond,1)

    condtrls = ismember(condMatrix,cond(ntype,:),'rows');
    ds.sa.type(condtrls,1) = ntype; % number of unique properties combinations (i.e. conditions)

    clear condtrls
end




