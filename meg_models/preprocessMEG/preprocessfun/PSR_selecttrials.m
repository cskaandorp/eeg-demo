function [select] = PSR_selecttrials(data,visualselect,conditions)
% PSR_SELECTTRIALS Get a specific subset of trials, that all fall within
% specified inclusion criteria (see PSR_getInclusionCriteria.m)
%
% Applied inclusion criteria
%   1. saccade latency
%   2. total duration of fixation trial
%
% Input
%   data            fieldtrip data (struct)
%   visualselect    visually inspected trials, struct with fields
%                       .accepted
%                       .rejected
%   condition       (optional) cell string, options
%                       - 'all'     all trials (default)
%                       - 'fll'     fixation - left  - low  SF
%                       - 'flh'     fixation - left  - high SF
%                       - 'frl'     fixation - right - low  SF
%                       - 'frh'     fixation - right - high SF
%                       - 'srl'     saccade  - right - low  SF
%                       - 'srh'     saccade  - right - high SF
%                       - 'srn'     saccade  - right - no stimulus
%-------------------------------------------------------------------------%

%% Parse input                  
% visual inspection
if ~exist('visualselect','var') || isempty(visualselect) || ...
   ~isfield(visualselect,'accepted') || ~isfield(visualselect,'rejected')
    error('Data must be visually inspected before further usage')
end

if ( length(visualselect.accepted) + length(visualselect.rejected) ) ~= length(data.time)
    error('Number of visually inspected trials does not match number of trials in data array')
end


% conditions
if ~exist('conditions','var') || isempty(conditions)
    conditions = 'all';
end

if ischar(conditions)
    conditions = {conditions};
end

%% Select: conditions           
fll = data.trialinfo(:,5)==0 & data.trialinfo(:,8)==1 & data.trialinfo(:,6)==0;
flh = data.trialinfo(:,5)==0 & data.trialinfo(:,8)==2 & data.trialinfo(:,6)==0;
frl = data.trialinfo(:,5)==0 & data.trialinfo(:,8)==1 & data.trialinfo(:,6)==1;
frh = data.trialinfo(:,5)==0 & data.trialinfo(:,8)==2 & data.trialinfo(:,6)==1;
srl = data.trialinfo(:,5)==1 & data.trialinfo(:,8)==1;
srh = data.trialinfo(:,5)==1 & data.trialinfo(:,8)==2;
srn = data.trialinfo(:,5)==1 & data.trialinfo(:,8)==0;
      
if any(ismember(conditions,'all'))
    selectCNDN = true(length(data.trial),1);
    
else
    selectCNDN = false(length(data.trial),1);
    
    if any(ismember(conditions,'fll'))
        selectCNDN = selectCNDN | fll;
    end
    
    if any(ismember(conditions,'flh'))
        selectCNDN = selectCNDN | flh;
    end
    
    if any(ismember(conditions,'frl'))
        selectCNDN = selectCNDN | frl;
    end
    
    if any(ismember(conditions,'frh'))
        selectCNDN = selectCNDN | frh;
    end
    
    if any(ismember(conditions,'srl'))
        selectCNDN = selectCNDN | srl;
    end
    
    if any(ismember(conditions,'srh'))
        selectCNDN = selectCNDN | srh;
    end
    
    if any(ismember(conditions,'srn'))
        selectCNDN = selectCNDN | srn;
    end
end

%% Select: inclusion criteria   
% sampling frequency
if isfield(data,'fsample')
    fs = data.fsample;
else
    fs = 1/unique(round(diff(data.time{1}),4));
end

% inclusion criteria
criteria = PSR_inclusionCriteria;

% saccade latencies(or S1 duration)
srt = round( ( data.trialinfo(:,17)-data.trialinfo(:,16) ) / (fs/1000) );

% include based on SRT (Saccade trials)
include_srt = data.trialinfo(:,5)==0 | (srt>=criteria.srt(1) & srt<=criteria.srt(2));

% include based on S1 duration (Fixation trials)
include_minTfix = data.trialinfo(:,5)==1 | srt>=criteria.minTfix - 1000/fs;

% which trials to include
selectINCLUDE = ( include_srt & include_minTfix );

%% Select: visual inspection    
selectVISUAL = false(length(data.trial),1);
selectVISUAL(visualselect.accepted) = true;

%% Select: FINAL                
select = find(selectCNDN & selectINCLUDE & selectVISUAL);


end