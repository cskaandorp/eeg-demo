function [maxVal] = maxval(cellIn,dim)
% MAXSIZE Find maximum size of arrays in cell array

if ~exist('dim','var') || isempty(dim)
    dim = 1;
end

% set initial length
maxVal = 0;

% loop over all cells
for k = 1:length(cellIn)
    cellMax = max(cellIn{k},[],dim);
    maxVal  = max(cellMax,maxVal);
end



end