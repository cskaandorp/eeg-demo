function [dprime] = computeDprime( stim, resp )
% DPRIME Compute d-prime
%
% Input
%   stim    matrix with stimulus presence (0=no stimulus, 1=stimulus), 
%           where rows are trials
%   resp    matrix with responses (0=no stimulus detected, 1=stimulus
%           detected), where rows are trials
%
%   dprime  sensitivity index*
%           *if hit rate/false alarm rate is at limits (0 or 1), the 
%           function adds 0.5 both to the number of hits and the number of
%           false alarms: loglinear approach (Hautus, 1995).
%
%                                                            J.H.F. 08-2017
%-------------------------------------------------------------------------%

% count number of hits and false alarms
hit.nresp   = sum(stim==resp & stim==1 & ~isnan(stim) & ~isnan(resp) );
hit.ntrials = sum(stim==1 & ~isnan(stim) & ~isnan(resp) );
fa.nresp    = sum(stim~=resp & stim==0 & ~isnan(stim) & ~isnan(resp) );
fa.ntrials  = sum(stim==0 & ~isnan(stim) & ~isnan(resp) );

% if number of hits/false alarms equals number of stimulus present/absent
% trials, respectively: add 0.5 both to the number of hits and the number 
% of false alarms: loglinear approach (Hautus, 1995)
iloglinear = hit.nresp==hit.ntrials | fa.nresp==fa.ntrials | hit.nresp==0 | fa.nresp==0;
if any(any(iloglinear))
    hit.nresp(iloglinear)   = hit.nresp(iloglinear) + 0.5;
    hit.ntrials(iloglinear) = hit.ntrials(iloglinear) + 1;
    fa.nresp(iloglinear)    = fa.nresp(iloglinear) + 0.5;
    fa.ntrials(iloglinear)  = fa.ntrials(iloglinear) + 1;
end

% compute hit rate and false alarm rate
hit.rate = hit.nresp ./ hit.ntrials;
fa.rate  = fa.nresp ./ fa.ntrials;

% compute d-prime
dprime = norminv( hit.rate ) - norminv( fa.rate );

end