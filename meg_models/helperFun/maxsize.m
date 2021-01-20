function [maxSz] = maxsize(cellIn,dim)
% MAXSIZE Find maximum size of arrays in cell array

if ~exist('dim','var') || isempty(dim)
    dim = 1;
end

% set initial length
maxSz = 0;

% loop over all cells
for k = 1:length(cellIn)
    cellSz = size(cellIn{k},dim);
    maxSz = max(cellSz,maxSz);
end



end