classdef AxisymmetricElasticity < AbstractProblem
    properties
        physicalDim = 2   % r, z
        dofPerNode = 2
        strainSize = 4    % εrr, εzz, εθθ, γrz
    end
    methods
        function obj = AxisymmetricElasticity(element)
            obj = obj@AbstractProblem(element);
        end

        function D = reduceTangent(obj, D3d)
            % 3D [xx, yy, zz, xy, yz, xz]
            % 2X [rr, zz, θθ, rz]
            % Соответствие: rr↔xx, zz↔zz, θθ↔yy, rz↔xz
            idx = [1, 3, 2, 6];
            D = D3d(idx, idx);
        end

        function sv = reduceStress(obj, sv3d)
            sv = sv3d([1, 3, 2, 6]);
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
