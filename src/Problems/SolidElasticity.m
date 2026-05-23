classdef SolidElasticity < AbstractProblem
    properties
        physicalDim = 3 % x, y, z
        dofPerNode = 3  % u, v, w
        strainSize = 6  % εxx, εyy, εzz, γxy, γyz, γxz
    end
    methods
        function obj = SolidElasticity(element, material)
            obj = obj@AbstractProblem(element, material);
        end

        function D = elasticityMatrix(obj)
            lambda = obj.material.firstLame;
            mu = obj.material.secondLame;
            D = blkdiag(...
                lambda*ones(3) + 2*mu*eye(3), ...
                mu*eye(3));
        end

        function B = strainDisplacementMatrix(obj, grad, ~, ~)
            numNodes = obj.element.numNodes;
            p = obj.dofPerNode;
            B = zeros(obj.strainSize, p*numNodes);

            B(1,1:p:end) = grad(1,:);                           %εxx
            B(2,2:p:end) = grad(2,:);                           %εyy
            B(3,3:p:end) = grad(3,:);                           %εzz
            B(4,1:p:end) = grad(2,:); B(4,2:p:end) = grad(1,:); %γxy
            B(5,2:p:end) = grad(3,:); B(5,3:p:end) = grad(2,:); %γyz
            B(6,1:p:end) = grad(3,:); B(6,3:p:end) = grad(1,:); %γxz
        end

        function vm = vonMises(obj, stress)
            sxx = stress(1,:); syy = stress(2,:); szz = stress(3,:);
            sxy = stress(4,:); syz = stress(5,:); sxz = stress(6,:);
            vm = sqrt(0.5*((sxx-syy).^2 + (syy-szz).^2 + (szz-sxx).^2 + 6*(sxy.^2+syz.^2+sxz.^2)));
        end
    end
end
