classdef PlaneStrainElasticity < AbstractProblem
    properties
        physicalDim = 2 % x, y
        dofPerNode = 2
        strainSize = 3  % %εxx, εyy, γxy
    end
    methods
        function obj = PlaneStrainElasticity(element, material)
            obj = obj@AbstractProblem(element, material);
        end
        function D = elasticityMatrix(obj)
            lambda = obj.material.firstLame;
            mu = obj.material.secondLame;
            D = blkdiag(...
                lambda*ones(2) + 2*mu*eye(2), ...
                mu);
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
