classdef C3D8 < Elasticity3D
    properties
        numNODE = 8
        numDOF = 24
    end
    methods
        function obj = C3D8(material,nquad)
            if nargin == 1
                nquad = 2;
            end
            obj = obj@Elasticity3D(material,nquad)
        end

        function N = shapeFunction(obj,xi) %TODO
            %           7____8        7____6
            %          /|   /| map   /|   /|
            % ^Z Y    5____6 | -->  8____5 |
            % | /     | 3__|_4      | 3__|_2
            % |/      |/   |/       |/   |/
            % 0___>X  1____2        4____1
            %
            
            map = [2;4;3;1;6;8;7;5];
            L = 0.5*(1 + [-xi;xi]);

            N = kron(kron(L([3;6]),L([2;5])),L([1;4]));
            N = N(map,:);
        end

        function dN = shapeGradient(obj,xi)
            map = [2;4;3;1;6;8;7;5];
            L = 0.5 * (1 + [-xi;xi]);
            dL = 0.5 * [-1;1];

            dN1 = kron(kron(L([3;6]),L([2;5])),dL);
            dN2 = kron(kron(L([3;6]),dL),L([1;4]));
            dN3 = kron(kron(dL,L([2;5])),L([1;4]));

            dN = [dN1,dN2,dN3];
            dN = dN(map,:);
        end
    end
end
