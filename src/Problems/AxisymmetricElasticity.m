classdef AxisymmetricElasticity < AbstractProblem
    properties
        physicalDim = 2   % r, z
        dofPerNode = 2
        strainSize = 4    % εrr, εzz, εθθ, γrz
    end
    methods
        function obj = AxisymmetricElasticity(element, material)
            obj = obj@AbstractProblem(element, material);
        end
        function D = elasticityMatrix(obj)
            lambda = obj.material.firstLame;
            mu = obj.material.secondLame;
            D = blkdiag(...
                lambda*ones(3) + 2*mu*eye(3), ...
                mu);
        end
        function B = strainDisplacementMatrix(obj, grad, N, nodeCoords)
            numNodes = obj.element.numNodes;
            p = obj.dofPerNode;
            B = zeros(obj.strainSize, p*numNodes);
            % Вычисляем радиус в точке интегрирования
            r = nodeCoords(1,:) * N;
            if r <= 0, r = 1e-12; end   % избегаем сингулярности на оси

            B(1,1:p:end) = grad(1,:);                           %εrr
            B(2,2:p:end) = grad(2,:);                           %εzz
            B(3,1:p:end) = N'./r;                               %εθθ
            B(4,1:p:end) = grad(2,:); B(4,2:p:end) = grad(1,:); %γrz
        end

        function vm = vonMises(obj, stress)
            srr = stress(1,:); szz = stress(2,:); stt = stress(3,:); srz = stress(4,:);
            vm = sqrt(0.5*((srr-szz).^2 + (szz-stt).^2 + (stt-srr).^2 + 6*srz.^2));
        end
    end
end
