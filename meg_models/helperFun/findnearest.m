function idx = findnearest(x,y)

idx = zeros(size(x));
for j = 1:size(x,1)
    for k = 1:size(x,2)
        idx(j,k) =  find(abs(x(j,k)-y)==min(abs(x(j,k)-y)),1,'first');
    end
end

end