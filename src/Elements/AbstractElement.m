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
    methods (Abstract)
        N = shapeFunction(obj,xi)
        dN = shapeGradient(obj,xi)
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
    end
end
