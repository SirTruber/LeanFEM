function validateGrid(grid)
    numNodes = rows(grid.nodes);
    ind = grid.hexas(:) > numNodes;
    if any(ind)
        nonExistedNodes = unique(grid.hexas(ind));
        [badElements,~] = ind2sub(size(grid.hexas), find(ind));
        badElements = unique(badElements);
        error('Non existed nodes with numbers %s finding in elements %s',mat2str(nonExistedNodes), mat2str(badElements'));
    end
    %TODO добавить дополнительные проверки, возможно уже в классе TopologyGroup
end
