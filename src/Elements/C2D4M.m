% N  [numNodes x 1];
% dN [numNodes x paramDim];
% xi [paramDim x 1];
classdef C2D4M < C2D4
    properties
      param = 1
    end
    methods
        function obj = C2D4M(param)
            obj.quadrature = GaussQuadrature(2, 1);
            if nargin == 1
                obj.param = param;
            end
        end

        function Ke = computeStiffness(obj, problem, nodeCoords, material)
        gamma = obj.getHourglass(nodeCoords);
        mu = material.secondLame;
        dof = problem.dofPerNode;

        integrand = @(xi, grad, detJ, N) ...
            obj.stiffnessIntegrand(problem, grad, N, nodeCoords, material)... % Обычный интегрант 
            + mu * obj.param * kron(gamma' * gamma, eye(dof));                % Для стабилизации
            
        Ke = obj.integrate(nodeCoords, integrand);
        end
          
        function gamma = getHourglass(obj, nodeCoords)
            H = [ones(obj.numNodes,1), nodeCoords'];
            Q = orth(H);
            v = [1 -1 1 -1];
            gamma = v - v*(Q*Q');
        end
    end
end
