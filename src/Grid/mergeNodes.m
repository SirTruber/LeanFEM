function grid = mergeNodes(grid, tol)
    % Сливает узлы, расстояние между которыми меньше tol.
    % Возвращает сетку с обновлёнными индексами элементов.
    if nargin < 2, tol = 1e-6; end
    nodes = grid.nodes';
    [uniqueNodes, ~, ic] = uniquetol(nodes, tol, 'DataScale', 1, 'ByRows', true);
    grid.nodes = uniqueNodes';
    % Обновить индексы в hexas
    hexas = grid.hexas;
    for i = 1:numel(hexas)
        hexas(i) = ic(hexas(i));
    end
    grid.hexas = hexas;
    grid.generateQuads();
end