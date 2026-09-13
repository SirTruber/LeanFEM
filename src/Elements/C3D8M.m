% N  [numNodes x 1];
% dN [numNodes x paramDim];
% xi [paramDim x 1];
classdef C3D8M < C3D8
    properties
        param = 1
    end
    methods
       function obj = C3D8M(param)
            obj.quadrature = GaussQuadrature(3, 1);
            if nargin == 1
                obj.param = param;
            end
       end

        function Ke = computeStiffness(obj, problem, nodeCoords, material)
            xi = obj.quadrature.points(:, 1);
            w  = obj.quadrature.weights(1);
            [grad, detJ] = obj.computeGradient(xi, nodeCoords);
            N = obj.shapeFunction(xi);

            B = problem.strainDisplacementMatrix(grad, N, nodeCoords);
            D = problem.elasticityMatrix(material);
            Klin = B' * D * B;

            gamma = obj.getHourglass(nodeCoords);
            mu = material.secondLame;
            dof = problem.dofPerNode;
            Kstab = mu * obj.param * kron(gamma' * gamma, eye(dof));
            Ke = (Klin + Kstab) * detJ * w;
        end
        
        function gamma = getHourglass(obj, nodeCoords)
            H = [ones(obj.numNodes,1), nodeCoords'];
            Q = orth(H);
            v = [ 1 -1  1 -1  1 -1  1 -1;
                  1  1 -1 -1  1  1 -1 -1;
                  1 -1 -1  1  1 -1 -1  1;
                  1 -1  1 -1 -1  1 -1  1 ];
            gamma = v - v*(Q*Q');
        end
    end
end
