classdef GaussQuadrature < handle
    properties (SetAccess = private)
        paramDim    % Размерность параметрического пространства
        nPoints1D   % число точек на каждом направлении
        points      % [dim × totalPoints] координаты точек в параметрическом пространстве
        weights     % [1 × totalPoints] веса (произведение одномерных весов)
    end

    methods
        function obj = GaussQuadrature(paramDim, nPoints1D)
            % Конструктор
            % paramDim - размерность (1,2,3)
            % nPoints - число точек Гаусса на каждом направлении
            obj.paramDim = paramDim;
            obj.nPoints1D = nPoints1D;
            [obj.points, obj.weights] = obj.generateTensorProduct();
        end

        function n = nPoints(obj)
            n = size(obj.points, 2);
        end
    end

    methods (Access = private)
        function [pts, w] = generateTensorProduct(obj)
            [p1D, w1D] = gausspoints(obj.nPoints1D);

            switch obj.paramDim
                case 1
                    pts = p1D(:)';
                    w   = w1D(:)';
                case 2
                    [X, Y] = meshgrid(p1D, p1D);
                    [Wx, Wy] = meshgrid(w1D, w1D);
                    pts = [X(:)'; Y(:)'];
                    w   = (Wx(:).*Wy(:))';
                case 3
                    [X, Y, Z] = meshgrid(p1D, p1D, p1D);
                    [Wx, Wy, Wz] = meshgrid(w1D, w1D, w1D);
                    pts = [X(:)'; Y(:)'; Z(:)'];
                    w   = (Wx(:).*Wy(:).*Wz(:))';
                otherwise
                    error('GaussQuadrature: Unsupported dimension %d', obj.paramDim);
            end
        end
    end
end
