%% Description              
%
% Per subject time-resolved decoding, locked to S1 onset
%
% NB: train and test sets are balanced for spatial frequency, orientation 
%     and phase of the grating
%-------------------------------------------------------------------------%

%% Init                  	
% initialize
clearvars; close all; clc;


%% Custom functions
addpath([cd filesep 'helperFun']);
addpath([cd filesep 'PSRFun']);


%% Parameters  
displaynow = true;          % list of subjectfiles
nchar      = 9;             % characters in subjectfile
timeradius = 5;             % for temporal 'searchlight'
nfolds     = 1;             % number of folds for cross-validation
ptest      = 0.1;           % proportion of data used as test-set to assess classifier accuracy

% FOR EEG EXAMPLE DATA
suffix     = { 'SF', 3; ...
               'OR', 4} ;   % strng = prop to-be classified; int = corresponding column with cond info in data.trialinfo
balance    = {'SF', 3 ; ...
              'OR', 4};     % Define which stim properties should be balanced during partitioning

% FOR MEG EXAMPLE DATA
suffix     = { 'SF', 8; 'OR', 10} ;
balance     = { 'SF', 8; 'OR', 10} ;

channels   = 'MEG';         % all MEG or EEG channels
classifier = 'LDA';         % 'LDA' or 'SVM'

% set folders
folderFT        = '/Users/casper/Downloads/EEG_Decoding/fieldtrip-20190910';
folderCoSMoMVPA = '/Users/casper/Downloads/EEG_Decoding/CoSMoMVPA';
% Matlab R2019a fix: download and compile libsvm in Matlab
folderLIBSVM    = '/Users/casper/Downloads/EEG_Decoding/libsvm';
folderIN        = '/Users/casper/Downloads/EEG_Decoding/PREPROCESSED/MEG';
folderOUT       = '/Users/casper/Downloads/EEG_Decoding/PREPROCESSED/';
extension       = '.mat';


% This ensures proper types for the folders, the extension and the
% suffix / balance
folderFT        = char(folderFT);
folderCoSMoMVPA = char(folderCoSMoMVPA);
folderLIBSVM    = char(folderLIBSVM);
folderIN        = char(folderIN);
folderOUT       = char(folderOUT);
extension       = char(extension);
suffix          = format_parameter_cell(suffix, 2);
balance         = format_parameter_cell(suffix, 2);


% add current path to make this notebook run from tmp folder
addpath(cd);

% add fieldtrip path
PSR_setpaths(folderFT, folderCoSMoMVPA, folderLIBSVM);

% subject
subjects = PSR_subjects(folderIN, extension, displaynow, nchar);



%% Loop over subjects     	
for isubj = 1:numel(subjects)
    %% Print message      	
    fprintf('\n%s\n',subjects{isubj});
    fileout = fullfile(folderOUT, strcat(subjects{isubj}, '.mat'));
    if exist(fileout,'file')
        continue
    end

    %% Load data
    tic
    [dataTmp]  = PSR_loadTimelock(folderIN,subjects{isubj},channels);
    toc;

    %% Make CoSMo dataset

    ds = PSR_mkCoSMoData(dataTmp, suffix, balance);
    cosmo_check_dataset(ds)
    
    clear data dataTmp

    
    %% MVPA                 
    for s = 1:size(suffix,1)
       
        % Hardcoded but does no real harm. Leave it?
        if  ismember( subjects{isubj}, {'19910219ANSL', '19910228FLPE'} ) && ...
                contains(suffix{s},'Phase')
            % no phase triggers for these subjects
            continue;
        end
        
        %% Partitions
        % select data
        % Hardcoded but does no real harm. Leave it? (added the 'else')
        if isfield(ds.sa,'fix') && s == 1
            dsTMP = cosmo_slice(ds, ds.sa.fix==0, 1);
        elseif isfield(ds.sa,'fix') && s == 4
            dsTMP = cosmo_slice(ds, ds.sa.fix==1, 1);
        else
            dsTMP = ds; % only rename
        end
        
        % set targets
        target_str = suffix{s,1};
        dsTMP.sa.targets = dsTMP.sa.(target_str);    
        
        % partitions
        partitions = PSR_mkCoSMoPartitions_BALANCE( dsTMP, nfolds, (1:length(dsTMP.sa.targets))', 1-ptest );
        partitions = cosmo_balance_partitions(partitions, dsTMP);
        
        train_indices = cat(2,partitions.train_indices{:});
        test_indices  = cat(2,partitions.test_indices{:});
        
        % time neihgborhood for searchlight in time
        time_nbrhood = cosmo_interval_neighborhood(dsTMP,'time','radius',timeradius);

        %% Classification   
        % pre-allocation
        ntime       = length(dsTMP.a.fdim.values{2});
        ntesttrials = size(test_indices,1);
        tmp_y       = int8( zeros( ntesttrials, ntime, nfolds) );
        tmp_yhat    = int8( zeros( ntesttrials, ntime, nfolds) );

        % print message
        fprintf('Classification %s\n', suffix{s} );
        counter = 0;
        tstart = tic;
        
        % loop through folds and time points
        parfor p = 1:nfolds
            
            fprintf('Fold %d/%d... ',p,nfolds);
            tic;
            
            % slice along sample attribute dimension
            ds_train = cosmo_slice(dsTMP, train_indices(:,p), 1);
            ds_test  = cosmo_slice(dsTMP, test_indices(:,p), 1);
            
            % loop over time points
            for t = 1:ntime
                % time mask: current timepoint
                timemask    = time_nbrhood.neighbors{t};
                ds_trainTMP = cosmo_slice(ds_train, timemask, 2);
                ds_testTMP  = cosmo_slice(ds_test, timemask, 2);
                
                % CLASSIFICATION (SVM or LDA)
                switch upper(classifier)
                    case 'SVM'
                        pred = cosmo_classify_svm(ds_trainTMP.samples, ds_trainTMP.sa.targets, ds_testTMP.samples);
                    case 'LDA'
                        pred = cosmo_classify_lda(ds_trainTMP.samples, ds_trainTMP.sa.targets, ds_testTMP.samples);
                end
                
                % add to classification arrays - where time is aligned to S1
                tmp_y(:,t,p)    = ds_testTMP.sa.targets;
                tmp_yhat(:,t,p) = pred;
            end
            
            fprintf('done! (%.2f secs)\n',toc);
        end
        
        % print message
        fprintf('\nTotal classification time: %.2f secs\n',toc(tstart));
        
        % Performance          
        % trials from all partitions
        S1.y.(suffix{s})    = double( reshape( permute(tmp_y,[1 3 2]), [], size(tmp_y,2), 1) );
        S1.yhat.(suffix{s}) = double( reshape( permute(tmp_yhat,[1 3 2]), [], size(tmp_yhat,2), 1) );
        S1.time = dsTMP.a.fdim.values{2};
        
        % accuracy
        S1.accuracy.(suffix{s}) = mean(S1.y.(suffix{s})==S1.yhat.(suffix{s}));
        
        % sensitivity locked to S1 onset
        S1.dprime.(suffix{s}) = NaN(1,ntime);
        for t = 1:ntime
            S1.dprime.(suffix{s})(t) = computeDprime( S1.y.(suffix{s})(:,t)-1, S1.yhat.(suffix{s})(:,t)-1 );
        end
        
    end
    
    %% Save data            
    save( fileout, 'S1' );
    
    % remove redundant variables
    clear ds S1
    
end



