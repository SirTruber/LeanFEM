classdef (Abstract) AbstractProblem < handle
    properties (Abstract)
        physicalDim     % размерность физического пространства
        dofPerNode      % число степеней свободы в узле
        strainSize      % количество компонент тензора деформаций/градиентов
    end
    properties (SetAccess = protected)
        element         % объект класса AbstractElement
        material        % struct с полями firstLame, secondLame, density и т.д.
        stiffnessMethod % function handle для жёсткости
    end
    methods (Abstract)
        % Возвращает матрицу упругости D [strainSize x strainSize]
        D = elasticityMatrix(obj)

        % Возвращает матрицу B [strainSize x (dofPerNode*numNodes)]
        B = strainDisplacementMatrix(obj, grad, N, nodeCoords)

        % Вычисляет объём элемента (интеграл от detJ по параметрической области)
        vol = volumeElement(obj, nodeCoords)
    end

    methods
        function obj = AbstractProblem(element, material)
            obj.element = element;
            obj.material = material;
            if ismethod(element, 'getHourglass')
                obj.stiffnessMethod = @obj.stiffnessMoment;
            else
                obj.stiffnessMethod = @obj.stiffnessFull;
            end
        end

        function Ke = stiffness(obj, nodeCoords)
            Ke = obj.stiffnessMethod(nodeCoords);
        end

        function Ke = stiffnessFull(obj, nodeCoords)
            numNodes = obj.element.numNodes;
            dofTotal = obj.dofPerNode * numNodes;
            Ke = zeros(dofTotal);

            for ip = 1:obj.element.quadrature.nPoints
                xi = obj.element.quadrature.points(:, ip);
                w = obj.element.quadrature.weights(ip);

                [grad, detJ] = obj.element.computeGradient(xi, nodeCoords);
                N = obj.element.shapeFunction(xi);

                B = obj.strainDisplacementMatrix(grad, N, nodeCoords);
                D = obj.elasticityMatrix();

                Ke = Ke + (B' * D * B) * detJ * w;
            end

            Ke = Ke * obj.volumeFactor(nodeCoords);
        end

        function Ke = stiffnessMoment(obj, nodeCoords)
            numNodes = obj.element.numNodes;
            dofTotal = obj.dofPerNode * numNodes;
            Ke = zeros(dofTotal);

            for ip = 1:obj.element.quadrature.nPoints
                xi = obj.element.quadrature.points(:, ip);
                w = obj.element.quadrature.weights(ip);

                [grad, detJ] = obj.element.computeGradient(xi, nodeCoords);
                N = obj.element.shapeFunction(xi);

                B = obj.strainDisplacementMatrix(grad, N, nodeCoords);
                D = obj.elasticityMatrix();

                gamma = obj.element.getHourglass(nodeCoords);
                Kstab = obj.element.param * obj.material.secondLame * kron(gamma'*gamma,eye(obj.dofPerNode));
                Ke = Ke + (B' * D * B + Kstab) * detJ * w;
            end

            Ke = Ke * obj.volumeFactor(nodeCoords);
        end

        function Me = mass(obj, nodeCoords)
            vol = obj.volumeElement(nodeCoords);
            dofTotal = obj.dofPerNode * obj.element.numNodes;
            Me = vol * obj.material.density * eye(dofTotal) / dofTotal;
        end

        function factor = volumeFactor(obj, nodeCoords)
            % Переопределяется в наследниках (например, толщина для плоского напряжения)
            factor = 1;
        end
    end
end
