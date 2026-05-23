classdef Assembler < handle
    properties (SetAccess = private)
        problem
        mesh
        mapping
    end
    methods
        function obj = Assembler(problem, mesh, mapping)
            obj.problem = problem;
            obj.mesh = mesh;
            if nargin < 3
                obj.mapping = UniformNodeMapping();
            else
                obj.mapping = mapping;
            end
        end

        function K = stiffness(obj)
            numNodes = obj.mesh.numNodes();
            numElements = obj.mesh.numElements();
            [i_glob,j_glob,totalDOF] = obj.mapping.globalIndices(obj.problem.dofPerNode, ...
                    obj.mesh.elements(1:numElements), ...
                    numNodes); % Вычисляем глобальные DOF

            stiffness = arrayfun(@(i) obj.problem.stiffness(obj.mesh.points(i)), ...
                1:numElements,'UniformOutput',false); % Вычисляем матрицы жёсткости сразу для всех элементов
            stiffness = cat(3, stiffness{:}); % Объединяем в 3D-массив
            K = sparse(i_glob(:), j_glob(:),stiffness(:),totalDOF,totalDOF); % Создаём глобальную матрицу
        end

        function M = mass(obj)
            numNodes = obj.mesh.numNodes();
            numElements = obj.mesh.numElements();
            [i_glob,j_glob,totalDOF] = obj.mapping.globalIndices(obj.problem.dofPerNode, ...
                    obj.mesh.elements(1:numElements), ...
                    numNodes);

            mass = arrayfun(@(i) obj.problem.mass(obj.mesh.points(i)), ...
                1:numElements,'UniformOutput',false); % Вычисляем матрицы масс сразу для всех элементов
            mass = cat(3, mass{:}); % Объединяем в 3D-массив
            M = sparse(i_glob(:), j_glob(:),mass(:),totalDOF,totalDOF); % Создаём глобальную матрицу
        end

        # function F = internalForce(obj, U) ... end
        # function F = externalForce(obj, load) ... end
        function strain = nodalStrain(obj, U)
            numNodes = obj.mesh.numNodes();
            strainSize = obj.problem.strainSize;
            strain = zeros(obj.problem.strainSize, numNodes);
            weight = zeros(1, numNodes);

            for e = 1:obj.mesh.numElements()
                nodes = obj.mesh.elements(e);
                nodeCoords = obj.mesh.points(e);
                Ue = U(:, nodes);
                w = obj.problem.nodeWeight(nodeCoords);
                Ve = sum(w);
                strainIntegral = obj.problem.strainIntergal(nodeCoords, Ue);
                strain(:, nodes) = strain(:, nodes) + strainIntegral .* (w/Ve);
                weight(nodes) = weight(nodes) + w;
            end
            strain = strain ./ weight;
        end

        function stress = nodalStress(obj, U)
            stress = obj.problem.elasticityMatrix() * obj.nodalStrain(U);
        end
    end
end
