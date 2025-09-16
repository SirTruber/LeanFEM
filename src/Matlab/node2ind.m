function ind = node2ind(dims, needDim, cord)
    I = repmat(needDim(:),1,numel(cord))(:);
    J = repelem(cord(:),numel(needDim));
    ind = sub2ind(dims, I, J);
end
