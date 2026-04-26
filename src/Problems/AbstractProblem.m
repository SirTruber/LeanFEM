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

        function vm = vonMises(obj, stress) end
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

        function strain = strainIntergal(obj, nodeCoords, Ue)
            strain = obj.element.integrate(nodeCoords, @(xi,grad,detJ,N) obj.strainDisplacementMatrix(grad, N, nodeCoords) * Ue(:));
        end

        function vol = volumeElement(obj, nodeCoords)
            vol = obj.element.integrate(nodeCoords, @(xi, grad, detJ, N) 1);
        end

        function weight = nodeWeight(obj, nodeCoords)
            weight = obj.element.integrate(nodeCoords, @(xi, grad, detJ, N) N)';
        end
        function factor = volumeFactor(obj, nodeCoords)
            % Переопределяется в наследниках (например, толщина для плоского напряжения)
            factor = 1;
        end
    end
end
