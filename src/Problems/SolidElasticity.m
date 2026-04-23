classdef SolidElasticity < AbstractProblem
    properties
        physicalDim = 3 % x, y, z
        dofPerNode = 3
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

        function vol = volumeElement(obj, nodeCoords)
            vol = 0;
            for ip = 1:obj.element.quadrature.nPoints
                xi = obj.element.quadrature.points(:, ip);
                w = obj.element.quadrature.weights(ip);
                detJ = det(obj.jacobian(xi,nodeCoords));
                vol = vol + detJ * w;
            end
        end
    end
end
