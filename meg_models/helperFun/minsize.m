function [minSz] = minsize(cellIn,dim)
% MINSIZE Find minimum size of arrays in cell array

if ~exist('dim','var') || isempty(dim)
    dim = 1;
end

% set initial length
minSz = Inf;

% loop over all cells
for k = 1:length(cellIn)
    cellSz = size(cellIn{k},dim);
    minSz = min(cellSz,minSz);
end



end