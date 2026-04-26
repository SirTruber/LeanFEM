% N  [numNodes x 1];
% dN [numNodes x paramDim];
% xi [paramDim x 1];
classdef C3D8 < AbstractElement
    properties
        numNodes = 8
        paramDim = 3
        quadrature = GaussQuadrature(3, 2)
    end
    methods
        function N = shapeFunction(obj,xi)
            %           7____8        7____6
            %          /|   /| map   /|   /|
            % ^Z Y    5____6 | -->  8____5 |
            % | /     | 3__|_4      | 3__|_2
            % |/      |/   |/       |/   |/
            % 0___>X  1____2        4____1
            %
            xi = xi(:);
            x = xi(1); y = xi(2); z = xi(3);

            N = 0.125 * [
                (1+x)*(1-y)*(1-z);
                (1+x)*(1+y)*(1-z);
                (1-x)*(1+y)*(1-z);
                (1-x)*(1-y)*(1-z);
                (1+x)*(1-y)*(1+z);
                (1+x)*(1+y)*(1+z);
                (1-x)*(1+y)*(1+z);
                (1-x)*(1-y)*(1+z)
            ];
        end

        function dN = shapeGradient(obj,xi)
            xi = xi(:);
            x = xi(1); y = xi(2); z = xi(3);
            dN = 0.125 * [
                 (1-y)*(1-z), -(1+x)*(1-z), -(1+x)*(1-y);
                 (1+y)*(1-z),  (1+x)*(1-z), -(1+x)*(1+y);
                -(1+y)*(1-z),  (1-x)*(1-z), -(1-x)*(1+y);
                -(1-y)*(1-z), -(1-x)*(1-z), -(1-x)*(1-y);
                 (1-y)*(1+z), -(1+x)*(1+z),  (1+x)*(1-y);
                 (1+y)*(1+z),  (1+x)*(1+z),  (1+x)*(1+y);
                -(1+y)*(1+z),  (1-x)*(1+z),  (1-x)*(1+y);
                -(1-y)*(1+z), -(1-x)*(1+z),  (1-x)*(1-y)
            ];
        end
    end
end
