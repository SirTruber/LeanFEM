classdef (Abstract) AbstractProblem < handle
    properties (Abstract)
        physicalDim     % размерность физического пространства
        dofPerNode      % число степеней свободы в узле
        strainSize      % количество компонент тензора деформаций/градиентов
    end
    properties (SetAccess = protected)
        element         % объект класса AbstractElement
    end
    methods
        % Возвращает матрицу упругости D [strainSize x strainSize]
        function D = elasticityMatrix(obj, material) end

        % Возвращает матрицу B [strainSize x (dofPerNode*numNodes)]
        function B = strainDisplacementMatrix(obj, grad, N, nodeCoords) end

        function G = gradientDisplacementMatrix(obj, grad, N, nodeCoords) end

        function vm = vonMises(obj, stress) end
    end

    methods
        function obj = AbstractProblem(element)
            obj.element = element;
        end

        function Ke = stiffness(obj, nodeCoords, material)
            Ke = obj.element.computeStiffness(obj, nodeCoords, material) * obj.volumeFactor(nodeCoords);
        end

        function Me = mass(obj, nodeCoords, material)
            % vol = obj.volumeElement(nodeCoords);
            % dofTotal = obj.dofPerNode * obj.element.numNodes;
            % Me = vol * material.density * eye(dofTotal) / dofTotal;
            Me = obj.element.computeMass(obj, nodeCoords, material) * obj.volumeFactor(nodeCoords);
        end

        function Ke = geometricStiffness(obj, nodeCoords, stress)
            % sigma = [strainSize x quadrature.nPoints]
            Ke = 0;
            % if ismethod(obj.element, 'getHourglass')
            %
            %     gamma = obj.element.getHourglass(nodeCoords);
            %     param = obj.element.param;
            %     % volumeStress = obj.vonMises(stress);
            %     volumeStress = sum(stress(1:3));
            %     Ke = 0.5 * volumeStress * param * kron(gamma'*gamma, eye(obj.dofPerNode));
            % end
            quadrature = obj.element.quadrature;
            for ip = 1:quadrature.nPoints
                xi = quadrature.points(:, ip);
                w = quadrature.weights(ip);

                [grad, detJ] = obj.element.computeGradient(xi, nodeCoords);
                N = obj.element.shapeFunction(xi);
                G = obj.gradientDisplacementMatrix(grad,N,nodeCoords);
                s = reshape(stress([1,4,5,4,2,6,5,6,3],ip),3,3); % Тензор второго ранга

                sigma0 = kron(s,eye(3));
                T = zeros(9);
                T(1,1) = 1; T(2,4) = 1; T(3,7) = 1; T(4,2) = 1; T(5,5) = 1; T(6,8) = 1; T(7,3) = 1; T(8,6) = 1; T(9,9) = 1;
                Sigma = sigma0 * (T - eye(9));
                Sigma = 0.5 * (Sigma + Sigma');
                Ke = Ke + 0.5 * G' * Sigma * G * detJ * w;
            % end
            end
        end

        function eps = computeStrain(obj, grad, N, nodeCoords, Ue)
            eps = obj.strainDisplacementMatrix(grad, N, nodeCoords) * Ue(:);
        end

        function sigma = computeStress(obj, eps, material)
            D = obj.elasticityMatrix(material);
            sigma = D * eps; % Закон Гука
        end

        function F_int = computeInternalForce(obj, nodeCoords, stress_IP)
            nQuad = obj.element.quadrature.nPoints;
            F_int = 0;

            for ip = 1:nQuad
                xi = obj.element.quadrature.points(:, ip);
                w = obj.element.quadrature.weights(ip);
                [grad, detJ] = obj.element.computeGradient(xi, nodeCoords);
                N = obj.element.shapeFunction(xi);
                B = obj.strainDisplacementMatrix(grad, N, nodeCoords);
                F_int = F_int + (B' * stress_IP(:,ip)) * detJ * w;
            end
            F_int = F_int * obj.volumeFactor(nodeCoords);
        end

        function strain = strainIntergal(obj, nodeCoords, Ue)
            strain = obj.element.integrate(nodeCoords, ...
                @(xi, grad, detJ, N) obj.computeStrain(grad, N, nodeCoords, Ue));
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
