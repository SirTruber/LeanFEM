classdef GaussQuadrature < handle
    properties (SetAccess = private)
        points      % [paramDim × totalPoints] координаты точек в параметрическом пространстве
        weights     % [1 × totalPoints] веса (произведение одномерных весов)
    end

    methods
        function obj = GaussQuadrature(paramDim, nPoints1D)
            % paramDim - размер параметрического пространства
            % nPoints1D - число точек Гаусса на каждом направлении

            [p1D, w1D] = gausspoints(nPoints1D);

            switch paramDim
                case 1
                    obj.points = p1D(:)';
                    obj.weights = w1D(:)';
                case 2
                    [X, Y] = meshgrid(p1D, p1D);
                    [Wx, Wy] = meshgrid(w1D, w1D);
                    obj.points = [X(:)'; Y(:)'];
                    obj.weights = (Wx(:).*Wy(:))';
                case 3
                    [X, Y, Z] = meshgrid(p1D, p1D, p1D);
                    [Wx, Wy, Wz] = meshgrid(w1D, w1D, w1D);
                    obj.points = [X(:)'; Y(:)'; Z(:)'];
                    obj.weights = (Wx(:).*Wy(:).*Wz(:))';
                otherwise
                    error('GaussQuadrature: Unsupported dimension %d', paramDim);
            end
        end

        function n = nPoints(obj)
            n = size(obj.points, 2);
        end
    end
end

function [x,w] = gausspoints(nquad)
    switch nquad
        case 1
            x = 0;
            w = 2;
        case 2
            x = [-1/sqrt(3); 1/sqrt(3)];
            w = [1; 1];
        case 3
            x = [-sqrt(3/5); 0; sqrt(3/5)];
            w = [5/9; 8/9; 5/9];
    end
    x = x(:);
    w = w(:);
end
