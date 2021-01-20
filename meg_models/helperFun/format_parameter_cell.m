function result = format_parameter_cell(x1, ncol)
    [~, cols] = size(x1);

    if cols ~= ncol
        x2 = reshape(x1,[],length(x1)/ncol).';
        dimensions = size(x2);
        for i=1:dimensions(1)
            x2{i}=char(x2{i});
        end
        result = x2;
    else
        result = x1;
    end
end