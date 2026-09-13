function merged = mergeGrids(varargin)
    % Объединяет несколько Grid3D в один (без слияния узлов).
    merged = Grid3D();
    nodes = [];
    hexas = [];
    offset = 0;
    for i = 1:nargin
        g = varargin{i};
        nodes = [nodes, g.nodes];
        hexas = [hexas, g.hexas + offset];
        offset = offset + size(g.nodes, 2);
    end
    merged.nodes = nodes;
    merged.hexas = hexas;
    merged.generateQuads();
end