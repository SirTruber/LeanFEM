classdef BoundaryCondition < handle
    properties
        nodes       % Индексы узлов [Nx1]
        values      % Значения [Nx3] для 3D
    end

    methods
        function obj = BoundaryCondition(nodes, values)
            obj.nodes = nodes;
            obj.values = values;
        end
    end
end
