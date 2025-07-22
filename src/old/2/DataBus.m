classdef DataBus < handle
    properties (Access = private)
        solvers %containers.Map
    end

    methods
        function obj = DataBus()
            obj.solvers = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end

        function registerSolver(obj, solver_name, solver_context)
            obj.solvers(solver_name) = solver_context;
            solver_context.materials = obj.materials;
        end

        function context = getContext(obj, name)
            assert(obj.solvers.isKey(name));
            context = obj.solvers(solver_name);
        end

        function sync()

        end

        function syncInterfaces(obj)
            % Для всех пар смежных регионов
            for edge = obj.interfaces
                solverA = obj.getSolver(edge.regionA);
                solverB = obj.getSolver(edge.regionB);

                % Обмен данными на границе
                dataA = solverA.getBoundaryData(edge);
                dataB = solverB.getBoundaryData(edge);

                solverA.applyBoundaryData(dataB);
                solverB.applyBoundaryData(dataA);
            end
        end
    end
end
