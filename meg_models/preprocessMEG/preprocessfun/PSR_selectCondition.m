function [select] = PSR_selectCondition(data,conditions)
% PSR_SELECTCLEAN Get a specific subset of trials within one condition
% Input
%   data            fieldtrip data (struct)
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

% get indices
select = find(selectCNDN);

end