function [data] = PSR_loadTimelock_MEG(datafolder,trlfolder,subfolder,subject,channels)
%% PSR_LOADTIMELOCK
% Hardcoded script for Jaspers MEG dataset used in preprocess_MEG.m
% Includes only trials that were accepted after visual inspection, and that
% fall within inclusion criteria as specified in PSR_inclusionCriteria
%
% Input
%   datafolder  string indicating location of '../TIMELOCKED'
%   subfolder   string indicating which subfolder of '../TIMELOCKED' to use
%   trlfolder   containing visually inspected trial rejections
%   subject     string with subject specification (part of filename)
%   channels    input for cfg.channel for ft_selectdata
%
% Output
%   data        structure contaning fieldtrip dataset
%-------------------------------------------------------------------------%


%% Load trial selection     
% check files in folder of this subjects
trlfiles = dir(fullfile(trlfolder, '*.mat'));

% index of subjects file
isubjtrl = find( arrayfun(@(x) ~isempty(strfind(trlfiles(x).name,subject)), 1:length(trlfiles)) );

% check file (only allow to load 1 file)
if isempty(isubjtrl)
    error('No files with visually inspected trials found for %s in %s',subject,trlfolder);
elseif length(isubjtrl)>1
    error('More than 1 file found for %s in %s',subject,trlfolder);
end

% load trial selection     
% -----------------------------------------------------------
% select = load([trlfolder filesep trlfiles(isubjtrl).name]);
% -----------------------------------------------------------
select = load( fullfile(trlfolder, trlfiles(isubjtrl).name) );

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
% ----------------------------------------------------           
% data = load([datafolder filesep files(isubj).name]);
% ---------------------------------------------------- 
data = load( fullfile(datafolder, files(isubj).name) );

%% Remove trials that were rejected after visual inspection
% get alignment
if strncmp(subfolder,'S1',2)
    alignment = 's1lock';
elseif strncmp(subfolder,'SAC',3)
    alignment = 'saclock';
end

% get trials to include
cfg              = [];
cfg.trials       = PSR_selecttrials( data.(alignment), select );
if exist('channels','var') && ~isempty(channels)
    cfg.channel = channels;
end

% store difference in badtrials
data.badtrials.n_excluded = single( length(data.(alignment).trial) - length(cfg.trials) );

% remove trials from data array
data.(alignment) = ft_selectdata( cfg, data.(alignment) );

% do the same for the eye tracking data
data.et.raw = data.et.raw(cfg.trials);
         
end