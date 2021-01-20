%% Preprocess MEG data
% prepares Jaspers dataset for further use in
% PSR_MVPA_crossvalidation_fix_main.m

%% set parameters
% Folders
folderFT        = '/Users/casper/Downloads/EEG_Decoding/fieldtrip-20190910';
folderCoSMoMVPA = '/Users/casper/Downloads/EEG_Decoding/CoSMoMVPA';
% Matlab R2019a fix: download and compile libsvm in Matlab
folderLIBSVM    = '/Users/casper/Downloads/EEG_Decoding/libsvm';
folderIN        = '/Users/casper/Downloads/EEG_Decoding/TIMELOCKED/S1';
folderTRL       = '/Users/casper/Downloads/EEG_Decoding/TRIALS/REJECTVISUAL';
folderOUT       = '/Users/casper/Downloads/EEG_Decoding/TRIALS';
extension       = '.mat';

% Parameters
displaynow  = true; % list of subjectfiles
nchar       = 9;     % characters in subjectfile
bws         = -0.2; % baseline window start (for baseline correction)
bwe         = 0;    % baseline window end (for baseline correction)
channels    = 'MEG'; 

% This ensures proper types for the folders and extension:
folderFT        = char(folderFT);
folderCoSMoMVPA = char(folderCoSMoMVPA);
folderLIBSVM    = char(folderLIBSVM);
folderIN        = char(folderIN);
folderTRL       = char(folderTRL);
folderOUT       = char(folderOUT);
extension       = char(extension);

% add current path to make this notebook run from tmp folder
addpath(cd)

% add fieldtrip path
PSR_setpaths(folderFT, folderCoSMoMVPA, folderLIBSVM);

% subject
subjects = PSR_subjects(folderIN, extension, displaynow, nchar);


%% preprocess
for isubj = 1:numel(subjects)
    %% Print message      	
    fprintf('\n%s\n',subjects{isubj});
    fileout = fullfile(folderOUT, strcat(subjects{isubj}, '.mat'));
    if exist(fileout,'file')
        continue
    end

    %% Load data
    tic
    [dataTmp]  = PSR_loadTimelock_MEG(folderIN,folderTRL,'S1',subjects{isubj},channels);
    toc;

    dataTmp = dataTmp.s1lock;
    dataTmp = rmfield(dataTmp, 'cfg');
    dataTmp = ft_struct2double(dataTmp);
    
    %% Preprocess
    % 1. baseline correction
    cfg = [];
    cfg.demean = 'yes';
    cfg.baselinewindow = [bws bwe];
    [dataTmp] = ft_preprocessing(cfg,dataTmp);


    % 2. standardize data per sensors
    i1 = find( abs(dataTmp.time{1}-bws) == min(abs(dataTmp.time{1}-bws)) );
    i2 = find( abs(dataTmp.time{1}-bwe) == min(abs(dataTmp.time{1}-bwe)) );
    bw_std = std( cell2mat( cellfun(@(x) x(:,i1:i2),dataTmp.trial,'UniformOutput',false) ), [], 2);
    dataTmp.trial = cellfun(@(x) bsxfun(@rdivide,x,bw_std), dataTmp.trial,'UniformOutput',false);


    % 3. select conditions
    cfg        = [];
    cfg.trials = PSR_selectCondition(dataTmp,{'fll','flh','frl','frh'}); % hardcoded?
    [dataTmp]  = ft_selectdata(cfg,dataTmp);

end      