function [minVal] = minval(cellIn,dim)
% MAXSIZE Find maximum size of arrays in cell array

if ~exist('dim','var') || isempty(dim)
    dim = 1;
end

% set initial length
minVal = 0;

% loop over all cells
for k = 1:length(cellIn)
    cellMax = min(cellIn{k},[],dim);
    minVal  = min(cellMax,minVal);
end



end