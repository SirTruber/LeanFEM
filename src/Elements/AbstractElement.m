% N  [numNodes x 1];
% dN [numNodes x paramDim];
% xi [paramDim x 1];
% nodeCoords [physicalDim x numNodes];
% J  [physicalDim x paramDim];
% grad [physicalDim x numNodes];

classdef (Abstract) AbstractElement < handle
    properties (Abstract)
        numNodes % Число узлов
        paramDim % Размерность параметрического пространства
        quadrature % объект GaussQuadrature
    end
    methods
        function N = shapeFunction(obj,xi) end
        function dN = shapeGradient(obj,xi) end
    end
    methods
        function J = jacobian(obj,xi,nodeCoords)
            dN = obj.shapeGradient(xi);
            J = nodeCoords * dN; % [dx/dxi,dx/deta;dy/dxi,dy/deta];
        end

        function [grad,detJ] =  computeGradient(obj,xi,nodeCoords)
            dN = obj.shapeGradient(xi);
            J = nodeCoords * dN;
            grad = J' \ dN';
            detJ = det(J);
        end

        function val = integrate(obj,nodeCoords,func)
            val = 0;

            for ip = 1:obj.quadrature.nPoints
                xi = obj.quadrature.points(:, ip);
                w = obj.quadrature.weights(ip);

                [grad, detJ] = obj.computeGradient(xi, nodeCoords);
                N = obj.shapeFunction(xi);

                val = val + func(xi,grad,detJ,N) * detJ * w;
            end
        end

        function Ke = computeStiffness(obj, problem, nodeCoords, material)
            integrand = @(xi, grad, detJ, N) ...
                obj.stiffnessIntegrand(problem, grad, N, nodeCoords, material);
            Ke = obj.integrate(nodeCoords, integrand);
        end
        function val = stiffnessIntegrand(obj, problem, grad, N, nodeCoords, material)
            B = problem.strainDisplacementMatrix(grad, N, nodeCoords);
            D = problem.elasticityMatrix(material);
            val = B' * D * B;
        end
        function Me = computeMass(obj, problem, nodeCoords, material)
            integrand = @(xi, grad, detJ, N) material.density * kron(N * N',eye(problem.physicalDim ));
            Me = obj.integrate(nodeCoords, integrand);
        end
    end
end
