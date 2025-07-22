classdef Region < handle
    properties
        dimension       %Размерность(число)
        name              % Уникальный идентификатор (строка)
        elements     % Индексы элементов (вектор [Nx1])
        nodes        % Индексы узлов (вычисляется автоматически)
        material_name     % Ключ материала (строка)
        boundary_conditions  % Граничные условия (struct)
    end

    methods
        function obj = Region(dimension,name, elements, material_name, bc)
            obj.dimension = dimension;
            obj.name = name;
            obj.elements = elements;
            obj.material_name = material_name;
%             obj.boundary_conditions = bc;
        end

        function calculate_nodes(obj, grid)
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
