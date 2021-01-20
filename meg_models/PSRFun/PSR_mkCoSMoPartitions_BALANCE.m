function [partitions] = PSR_mkCoSMoPartitions_BALANCE( ds, n, itrain, ptrain, itest, ptest )
% PSR_MKCOSMOPARTITION_BALANCE Make partitions of CoSMo dataset for MVPA
% 
% Input
%   ds      CoSMo dataset
%   n       number of partitions
%   itrian  indices of trials that can be used for training
%   ptrain  proportion of 'itrain' that should be used for training
%   itest*  (optional) indices of trials that can be used for testing
%   ptest*  (optional) propotion of 'itest' that should be used for testing
%
%   *If neither 'itest' nor 'ptest' are provided,
%       itest = itrain;
%       ptest = 1-ptrain;
%    If only 'itest' is provided, but 'ptest' is empty
%       ptest = 1;
%
% NEW: balance spatial frequency, orientation and phase
%-------------------------------------------------------------------------%

%% Check input          
if ~exist('itest','var') || isempty(itest)
    itest = itrain;
    ptest = 1-ptrain;
end

if ~exist('ptest','var') || isempty(ptest)
    ptest = 1;
end

% make sure there are at least some trials for training and testing
if ptrain==0 || ptest==0
    error('Unable to create partitions when proportion of training or testing data is zero');
elseif ptrain>1 || ptrain<0 || ptest>1 ||ptest<0
    error('Unable to create partitions when proportion of training or testing data <0 or >1');
end

%% Balance targets      
%--------------------%
% which trials from the training data belong to which trial type*
% *there are 8 trial types: 8 different combinations of SF, ORI and PHASE
train.type = arrayfun(@(x) find(ds.sa.type(itrain)==x), 1:max(ds.sa.type), 'UniformOutput',false);
test.type = arrayfun(@(x) find(ds.sa.type(itest)==x), 1:max(ds.sa.type), 'UniformOutput',false);

% how many of each target in training set
train.npertype = floor( min( cellfun(@length, train.type) ) * ptrain );
test.npertype  = ceil(min( cellfun(@length, test.type) ) * ptest );
%--------------------%



%--------------------%
% check types per target class
% which types belong to which class of the target?
uniqTarTrain = unique(ds.sa.targets(itrain));
uniqTarTest = unique(ds.sa.targets(itrain));

if ~all(uniqTarTrain==uniqTarTest)
    error('Training and test set contain different targets');
else 
    uniqTar = uniqTarTrain;
end

train.typesclassA = unique( ds.sa.type( ds.sa.targets(itrain)==uniqTar(1) ) );
train.typesclassB = unique( ds.sa.type( ds.sa.targets(itrain)==uniqTar(2) ) );
test.typesclassA  = unique( ds.sa.type( ds.sa.targets(itest)==uniqTar(1) ) );
test.typesclassB  = unique( ds.sa.type( ds.sa.targets(itest)==uniqTar(2) ) );

if length(train.typesclassA) ~= length(train.typesclassB)
    error('Each target class in the training set should consist of 4 trial types');
elseif length(test.typesclassA) ~= length(test.typesclassB)
    error('Each target class in the test set should consist of 4 trial types');
end
%--------------------%

%% Make partitions      
partitions.train_indices = cell(1,n);
partitions.test_indices  = cell(1,n);

for k = 1:n
    
    % training set
    tmp.train = cellfun(@(x) randsample( x, train.npertype, false)', train.type, 'UniformOutput', false);

    % test set
    if all( ~ismember(itest,itrain) )
        tmp.test = cellfun(@(x) randsample( x, test.npertype, false)', test.type, 'UniformOutput', false);
    else
        tmp.test = cellfun(@(x,y) randsample( x(~ismember(x,y)), test.npertype ,false)', test.type, tmp.train, 'UniformOutput', false);
    end

    % add to partitions structure
	partitions.train_indices{k} = itrain( cell2mat( tmp.train )' );
    partitions.test_indices{k}  = itest( cell2mat( tmp.test )' );

    % check whether not double dipping
    if any(ismember(partitions.train_indices{k},partitions.test_indices{k}))
        error('Double dipping: same trials in training and test set');
    end
end
