classdef RegionData < handle
    properties
        dimension   % Размерность(число)
        elements    % Индексы элементов (вектор [Nx1])
        nodes       % Индексы узлов     (вектор [Mx1]) (вычисляется автоматически)
    end

    methods
        function obj = RegionData(dim, target, grid)
            obj.dimension = dim;
            switch dim
                case 0
                    obj.elements = grid.select('nodes',target);
                    obj.nodes = unique(obj.elements);
                case 2
                    obj.elements = grid.select('quads',target);
                    obj.nodes = unique(grid.quads(obj.elements,:));
                case 3
                    obj.elements = grid.select('hexas',target);
                    obj.nodes = unique(grid.hexas(obj.elements,:));
            end
        end
    end
end
