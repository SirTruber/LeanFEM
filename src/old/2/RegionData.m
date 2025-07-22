classdef RegionData < handle
    properties
        dimension   % Размерность(число)
        elements    % Индексы элементов (вектор [Nx1])
        nodes       % Индексы узлов     (вектор [Mx1]) (вычисляется автоматически)
    end

    methods
        function calculateNodes(obj, grid)
            all_nodes = [];
            switch obj.dimension
                case 0
                    all_nodes = obj.elements;
                case 2
                    all_nodes = grid.quads(obj.elements,:);
                case 3
                    all_nodes = grid.hexas(obj.elements,:);
            end
            obj.nodes = unique(all_nodes(:));
        end
    end
end
