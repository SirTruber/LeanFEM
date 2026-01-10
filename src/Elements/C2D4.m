classdef C2D4 < Elasticity2D
    properties
        numNODE = 4
        numDOF = 8
    end
    methods
        function obj = C2D4(material,nquad)
            if nargin == 1
                nquad = 2;
            end
            obj = obj@Elasticity2D(material,nquad);
        end

        function N = shapeFunction(obj,xi) 
            %  4____3
            %  |    |
            %  |    |
            %  1____2
            % Ni = 0.25 * (1+xi_i*xi)*(1+eta_i*eta)
            
            m = 1 - xi; % [1 - xi(1), 1 - xi(2)]
            p = 1 + xi; % [1 + xi(1), 1 + xi(2)]

            N = 0.25 * [m(1)*m(2);p(1)*m(2);p(1)*p(2);m(1)*p(2)];
        end

        function dN = shapeGradient(obj,xi)
            m = 1 - xi; % [1 - xi(1), 1 - xi(2)]
            p = 1 + xi; % [1 + xi(1), 1 + xi(2)]
            dN = 0.25 * [[-m(2);m(2);p(2);-p(2)],[-m(1);-p(1);p(1);m(1)]];
        end
    end
end
