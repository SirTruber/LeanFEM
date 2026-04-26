% N  [numNodes x 1];
% dN [numNodes x paramDim];
% xi [paramDim x 1];
classdef C2D4 < AbstractElement
    properties
        numNodes = 4
        paramDim = 2
        quadrature = GaussQuadrature(2, 2)
    end
    methods
        function N = shapeFunction(obj,xi)
            % 3____2
            % |    |
            % |    |
            % 4____1
            %
            xi = xi(:);
            x = xi(1); y = xi(2);
            N = 0.25 * [
                (1 + x) * (1 - y);
                (1 + x) * (1 + y);
                (1 - x) * (1 + y);
                (1 - x) * (1 - y)
            ];
        end

        function dN = shapeGradient(obj,xi)
            xi = xi(:);
            x = xi(1); y = xi(2);
            dN = 0.25 * [
                 (1 - y), -(1 + x);
                 (1 + y),  (1 + x);
                -(1 + y),  (1 - x);
                -(1 - y), -(1 - x)
            ];
        end
    end
end
