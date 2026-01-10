classdef (Abstract) Element < handle
    properties (Abstract)
        numNODE % Число узлов
        numDIM % Число степеней свободы в узле
        numDOF % Число степеней свободы в элементе
    end
    properties
        gaussP % Координаты(одномерные) точек Гаусса
        gaussW % Веса точек Гаусса
    end
    methods (Abstract)
        N = shapeFunction(obj,xi);
        dN = shapeGradient(obj, xi);
        v = volume(obj,nodeCoords); % Обычно может быть вычисленно с помощью определителей Якоби
    end
    methods 
        function obj = Element(nquad)
            [obj.gaussP,obj.gaussW] = gausspoints(nquad);
        end
        
        function J = jacobian(obj,xi,nodeCoords)
            J = nodeCoords * obj.shapeGradient(xi); % [dx/dxi,dx/deta;dy/dxi,dy/deta];
        end

        function [grad,detJ] =  computeGradient(obj,xi,nodeCoords)
            dN = obj.shapeGradient(xi);
            J = obj.jacobian(xi,nodeCoords);
            grad = transpose(J)\transpose(dN);
            detJ = det(J);
        end
    end
end
