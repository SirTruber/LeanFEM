classdef (Abstract) AbstractProblem < handle
    properties (Abstract)
        physicalDim     % размерность физического пространства
        dofPerNode      % число степеней свободы в узле
        strainSize      % количество компонент тензора деформаций/градиентов
    end
    properties (SetAccess = protected)
        element         % объект класса AbstractElement
        material        % struct с полями firstLame, secondLame, density и т.д.
    end
    methods (Abstract)
        % Возвращает матрицу упругости D [strainSize x strainSize]
        function D = elasticityMatrix(obj) end

        % Возвращает матрицу B [strainSize x (dofPerNode*numNodes)]
        function B = strainDisplacementMatrix(obj, grad, N, nodeCoords) end

        % Вычисляет объём элемента (интеграл от detJ по параметрической области)
        function vol = volumeElement(obj, nodeCoords) end
    end

    methods
        function obj = AbstractProblem(element, material)
            obj.element = element;
            obj.material = material;
        end

        function Ke = stiffness(obj, nodeCoords)
            if ismethod(obj.element, 'getHourglass')
                gamma = obj.element.getHourglass(nodeCoords);
                mu = obj.material.secondLame;
                param = obj.element.param;
                Kstab = mu * param * kron(gamma'*gamma, eye(obj.dofPerNode));
                integrand = @(xi, grad, detJ, N) stiffnessMoment(obj, grad, N, nodeCoords, Kstab);
            else
                integrand = @(xi, grad, detJ, N) stiffnessFull(obj, grad, N, nodeCoords);
            end
            Ke = obj.element.integrate(nodeCoords, integrand) * obj.volumeFactor(nodeCoords);
        end

        function val = stiffnessFull(obj, grad, N, nodeCoords)
            B = obj.strainDisplacementMatrix(grad, N, nodeCoords);
            D = obj.elasticityMatrix();
            val = B' * D * B;
        end

        function val = stiffnessMoment(obj, grad, N, nodeCoords, Kstab)
            B = obj.strainDisplacementMatrix(grad, N, nodeCoords);
            D = obj.elasticityMatrix();
            val = B' * D * B + Kstab;
        end

        function Me = mass(obj, nodeCoords)
            vol = obj.volumeElement(nodeCoords);
            dofTotal = obj.dofPerNode * obj.element.numNodes;
            Me = vol * obj.material.density * eye(dofTotal) / dofTotal;
        end

        function [strain, stress] = evaluateStrainAndStress(obj, mesh, U)
        % Возвращает strain [strainSize × numNodes], stress [strainSize × numNodes]

        numNodes = mesh.numNodes();
        strain = zeros(obj.strainSize, numNodes);
        weight = zeros(1, numNodes);

        for e = 1:mesh.numElements()
            nodes = mesh.elements(e);                     % индексы узлов элемента
            nodeCoords = mesh.points(e);                  % [physicalDim × NodePerElem]
            Ue = U(:, nodes);                             % перемещения элемента

            for ip = 1:obj.element.quadrature.nPoints()
                xi = obj.element.quadrature.points(:, ip);
                w  = obj.element.quadrature.weights(ip);
                [grad, detJ] = obj.element.computeGradient(xi, nodeCoords);
                N = obj.element.shapeFunction(xi);
                B = obj.strainDisplacementMatrix(grad, N, nodeCoords);

                strain_ip = B * Ue(:);                    % деформации в точке интегрирования
                for j = 1:length(nodes)
                    strain(:, nodes(j)) = strain(:, nodes(j)) + ...
                        N(j) * strain_ip * detJ * w * obj.volumeFactor(nodeCoords);
                    weight(nodes(j)) = weight(nodes(j)) + ...
                        N(j) * detJ * w * obj.volumeFactor(nodeCoords);
                end
            end
        end

        strain = strain ./ weight;
        D = obj.elasticityMatrix();
        stress = D * strain;
    end
        function factor = volumeFactor(obj, nodeCoords)
            % Переопределяется в наследниках (например, толщина для плоского напряжения)
            factor = 1;
        end
    end
end
