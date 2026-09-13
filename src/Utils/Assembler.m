classdef Assembler < handle
    properties (SetAccess = private)
        problem
        mesh
        mapping
        materials
    end
    methods
        function obj = Assembler(problem, mesh, materials, mapping)
            obj.problem = problem;
            obj.mesh = mesh;
            if iscell(materials)
                obj.materials = materials;
            else
                obj.materials = {materials};
            end
            if nargin < 4
                obj.mapping = UniformNodeMapping();
            else
                obj.mapping = mapping;
            end
        end

        function K = stiffness(obj)
            numElements = obj.mesh.numElements();
            [i_glob,j_glob,totalDOF] = obj.mapping.globalIndices( ...
                    obj.problem.dofPerNode, ...
                    obj.mesh.elements(1:numElements), ...
                    obj.mesh.numNodes()); % Вычисляем глобальные DOF

            stiffness = arrayfun(@(e) obj.problem.stiffness( ... % Вычисляем матрицы жёсткости сразу для всех элементов
                obj.mesh.points(e), ... % координаты узлов элемента
                obj.materials{obj.mesh.materialID(e)}), ... % материал элемента
                1:numElements,'UniformOutput',false); 
            stiffness = cat(3, stiffness{:}); % Объединяем в 3D-массив
            K = sparse(i_glob(:), j_glob(:),stiffness(:),totalDOF,totalDOF); % Создаём глобальную матрицу
        end

        function M = mass(obj)
            numElements = obj.mesh.numElements();
            [i_glob,j_glob,totalDOF] = obj.mapping.globalIndices( ...
                    obj.problem.dofPerNode, ...
                    obj.mesh.elements(1:numElements), ...
                    obj.mesh.numNodes());

            mass = arrayfun(@(e) obj.problem.mass( ... % Вычисляем матрицы масс сразу для всех элементов
                obj.mesh.points(e), ... % координаты узлов элемента
                obj.materials{obj.mesh.materialID(e)}), ... % материал элемента
                1:numElements,'UniformOutput',false); 
            mass = cat(3, mass{:}); % Объединяем в 3D-массив
            M = sparse(i_glob(:), j_glob(:),mass(:),totalDOF,totalDOF); % Создаём глобальную матрицу
        end

        function KG = geometricStiffness(obj, stress_IP)
            numElements = obj.mesh.numElements();
            [i_glob,j_glob,totalDOF] = obj.mapping.globalIndices( ...
                   obj.problem.dofPerNode, ...
                   obj.mesh.elements(1:numElements), ...
                   obj.mesh.numNodes());
    
            gStiffness = arrayfun(@(e) obj.problem.geometricStiffness( ...
                obj.mesh.points(e), ...    % координаты узлов элемента
                stress_IP(:, :, e)), ...   % напряжения в IP-точках элемента
                1:numElements, 'UniformOutput', false);
    
            % Объединяем локальные матрицы в 3D-массив
            gStiffness = cat(3, gStiffness{:});
    
            % Собираем глобальную разреженную матрицу
            KG = sparse(i_glob(:), j_glob(:), gStiffness(:), totalDOF, totalDOF);
        end
        
        function F_int = internalForce(obj, stress_IP)
            % Вычисляет усилия от напряжения во всех точках интегрирования.
            % Вход: stress_IP – деформации во всех точках интегрирования [strainSize x nQuad x numElements]
            % Выход: F_int – [dofPerNode x numNodes]
    
            F_int = zeros(size(obj.mesh.nodes));
    
            for e = 1:obj.mesh.numElements()
                nodes = obj.mesh.elements(e);
                nodeCoords = obj.mesh.points(e);
        
                F_local = obj.problem.computeInternalForce(nodeCoords, stress_IP(:,:,e));
                F_int(:,nodes) = F_int(:,nodes) + reshape(F_local,obj.problem.dofPerNode,[]);
            end
        end

        % function F = externalForce(obj, load) ... end
        function strain = nodalStrain(obj, U)
            % Вход: U – глобальный вектор перемещений (dofPerNode x numNodes)
            numNodes = obj.mesh.numNodes();
            strain = zeros(obj.problem.strainSize, numNodes);
            weight = zeros(1, numNodes);

            for e = 1:obj.mesh.numElements()
                nodes = obj.mesh.elements(e);
                nodeCoords = obj.mesh.points(e);
                Ue = U(:, nodes);
                w = obj.problem.nodeWeight(nodeCoords);
                Ve = sum(w);
                Eps = obj.problem.strainIntergal(nodeCoords, Ue);
                strain(:, nodes) = strain(:, nodes) + Eps .* (w/Ve);
                weight(nodes) = weight(nodes) + w;
            end
            strain = strain ./ weight;
        end

        function stress = nodalStress(obj, U)
            % Вход: U – глобальный вектор перемещений (dofPerNode x numNodes)
            numNodes = obj.mesh.numNodes();
            stress = zeros(obj.problem.strainSize, numNodes);
            weight = zeros(1, numNodes);

            for e = 1:obj.mesh.numElements()
                nodes = obj.mesh.elements(e);
                nodeCoords = obj.mesh.points(e);
                Ue = U(:, nodes);
                w = obj.problem.nodeWeight(nodeCoords);
                Ve = sum(w);
                Eps = obj.problem.strainIntergal(nodeCoords, Ue);
                mat = obj.materials{obj.mesh.materialID(e)};
                sigma = obj.problem.computeStress(Eps,mat);
                stress(:, nodes) = stress(:, nodes) + sigma .* (w/Ve);
                weight(nodes) = weight(nodes) + w;
            end
            stress = stress ./ weight;
        end

        function strain_IP = integrationPointStrain(obj, U)
        % Вычисляет деформации во всех точках интегрирования.
        % Вход: U – глобальный вектор перемещений (dofPerNode x numNodes)
        % Выход: strain_IP – [strainSize x nQuad x numElements]
   
            
            numElems = obj.mesh.numElements();
            nQuad = obj.problem.element.quadrature.nPoints;
            strain_IP = zeros(obj.problem.strainSize, nQuad, numElems);
    
            for e = 1:numElems
                nodes = obj.mesh.elements(e);
                nodeCoords = obj.mesh.points(e);
                Ue = U(:, nodes);
        
                for ip = 1:nQuad
                    xi = obj.problem.element.quadrature.points(:, ip);
                    [grad, ~] = obj.problem.element.computeGradient(xi, nodeCoords);
                    N = obj.problem.element.shapeFunction(xi);
                    strain_IP(:, ip, e) = obj.problem.computeStrain(grad, N, nodeCoords, Ue);
                end
            end
        end
        
        function stress_IP = integrationPointStress(obj, U)
        % Вычисляет напряжения во всех точках интегрирования.
        % Вход: U – глобальный вектор перемещений (dofPerNode x numNodes)
        % Выход: stress_IP – [strainSize x nQuad x numElements]
    
            numElems = obj.mesh.numElements();
            nQuad = obj.problem.element.quadrature.nPoints;
            stress_IP = zeros(obj.problem.strainSize, nQuad, numElems);
    
            for e = 1:numElems
                nodes = obj.mesh.elements(e);
                nodeCoords = obj.mesh.points(e);
                Ue = U(:, nodes);

                material = obj.materials{obj.mesh.materialID(e)};
        
                for ip = 1:nQuad
                    xi = obj.problem.element.quadrature.points(:, ip);
                    [grad, ~] = obj.problem.element.computeGradient(xi, nodeCoords);
                    N = obj.problem.element.shapeFunction(xi);
                    eps = obj.problem.computeStrain(grad, N, nodeCoords, Ue);
                    stress_IP(:, ip, e) = obj.problem.computeStress(eps, material);
                end
            end
        end
    end
end
