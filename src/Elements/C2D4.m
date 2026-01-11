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
            % 3____4         3____2
            % |    |   map   |    |
            % |    |   -->   |    |
            % 1____2         4____1
            % 
            
            map = [2;4;3;1];
            L = 0.5*(1 + [-xi;xi]);

            N = kron(L([2;4]),L([1;3]));
            N = N(map,:);
        end

        function dN = shapeGradient(obj,xi)
            map = [2;4;3;1];
            L = 0.5 * (1 + [-xi;xi]);
            dL = 0.5 * [-1;1];

            dN1 = kron(L([2;4]),dL);
            dN2 = kron(dL,L([1;3]));

            dN = [dN1,dN2];
            dN = dN(map,:);
        end
    end
end
