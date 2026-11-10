classdef PlaneStrainElasticity < AbstractProblem
    properties
        physicalDim = 2 % x, y
        dofPerNode = 2  % u, v
        strainSize = 3  % %εxx, εyy, γxy
    end
    methods
        function obj = PlaneStrainElasticity(element)
            obj = obj@AbstractProblem(element);
        end

        function D = reduceTangent(obj, D3d)
        % Voigt: [xx, yy, zz, xy, yz, xz] → [xx, yy, xy]
            idx = [1, 2, 4];
            D = D3d(idx, idx);
        end

        function sv = reduceStress(obj, sv3d)
            sv = sv3d([1, 2, 4]);
        end

        function B = strainDisplacementMatrix(obj, grad, ~, ~)
            % grad - [2 x numNodes]
            numNodes = obj.element.numNodes;
            p = obj.dofPerNode;
            B = zeros(obj.strainSize, p*numNodes);

            B(1,1:p:end) = grad(1,:);                           %εxx
            B(2,2:p:end) = grad(2,:);                           %εyy
            B(3,1:p:end) = grad(2,:); B(3,2:p:end) = grad(1,:); %γxy
        end

        function vm = vonMises(obj, stress)
            sxx = stress(1,:); syy = stress(2,:); sxy = stress(3,:);
            vm = sqrt(0.5*((sxx-syy).^2 + sxx.^2 + syy.^2 + 6*sxy.^2));
        end
    end
end
