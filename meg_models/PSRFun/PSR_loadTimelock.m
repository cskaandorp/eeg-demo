function [data] = PSR_loadTimelock(datafolder,subject,channels)
%% PSR_LOADTIMELOCK
% Loads preprocessed dataset, checks whether it is a fieldtrip format and
% timelocks if necessary.
%
% Input
%   datafolder  string indicating location of '../TIMELOCKED'
%   subject     string with subject specification (part of filename)
%   channels    input for cfg.channel for ft_selectdata
%
% Output
%   data        structure contaning timelocked fieldtrip dataset
%-------------------------------------------------------------------------%

%% Load dataset                
% check files in folder of this subjects
% -------------------------------------------
% files = dir( [datafolder filesep '*.mat'] );
% -------------------------------------------
files = dir(fullfile(datafolder, '*.mat'));

% index of subjects file
isubj = find( arrayfun(@(x) ~isempty(strfind(files(x).name,subject)), 1:length(files)) );

% check file (only allow to load 1 file)
if isempty(isubj)
    error('No files found for subject %s in %s',subject,datafolder);
elseif length(isubj)>1
    error('More than 1 file found for subject %s in %s',subject,datafolder);
end

% load file     
data = load( fullfile(datafolder, files(isubj).name) );

% check whether file already has a struct name
if numel(fieldnames(data)) == 1
        structName  = fieldnames(data);      % Find original structname, which can be variable
        data        = data.(structName{1});  % And rename it uniformly
end

%% check dataset
% check what kind of files we're dealing with, so we know what to do next
type = ft_datatype(data);

switch type    
    case 'timelock' % keep data as is
            fprintf('\nTimelocked fieldtrip dataset\n')
    
    case 'raw' % timelock data (works only for EEG now)
            fprintf('\nRaw fieldtrip dataset\n')

            % timelock ft dataset
            cfg         = [];
            cfg.keeptrials = 'yes';     % don't average over trials
            cfg.channel    = channels;  % selected MEG/EEG channels
            data_tl        = ft_timelockanalysis(cfg, data);
            
            % return timelocked data
            data = data_tl;
            data = rmfield(data, 'cfg');
        
    case 'unknown' % Throw an error
            error('Unknown non-fieldtrip dataset. Make sure your dataset is in fieldtrip format (raw/timelocked).')
        
end        
end