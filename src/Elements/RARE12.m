classdef RARE12 < Elasticity3D
    properties
        numNODE = 8
        numDOF = 24
    end
    methods
        function obj = RARE12(material,nquad)
            if nargin == 1
                nquad = 1;
            end
            obj = obj@Elasticity3D(material,nquad)
        end

        function N = shapeFunction(obj,xi) %TODO
            %           0____3      
            %          /|   /|     
            % ^Z Y    4____0 |   3  
            % | /     | 2__|_0   | 4 
            % |/      |/   |/    |/   
            % 0___>X  0____1     1____2   
            %

            %xi = xi(:);
            %N = zeros(obj.numNODE,1);
            %N([1;8;6;3]) = [1 - sum(xi);xi(1);xi(2);xi(3)];
            N = 1/16 * ones(8,1); %TEST ONLY
        end

        function dN = shapeGradient(obj,xi)
            dN = zeros(obj.numNODE,obj.numDIM);
            dN([1;8;6;3],:) = [-ones(1,obj.numDIM);eye(obj.numDIM)];
        end

        function U = interpolateSlave(obj,grid,U,bc)
            for i = 1:grid.numElements()
                nodes = grid.elements(i);
                points = grid.points(i);

                grad = obj.computeGradient([0;0;0],points);
                Ugrad = U(:,nodes) * grad'; % Градиент перемещений. Симметричная часть будет представлять матрицу деформаций
                for j = [2,4,5,7]
                    adjacenty = grid.elements == nodes(j); % Находим соседние узлы
                    numAdj = sum(adjacenty(:)); % Находим кол-во соседних узлов
                    w = 1 / numAdj; % Вклад каждого узла будет уменьшаться при увеличении количества узлов  
                    distance = points(:,j) - points(:,1); % Расстояние до первого узла
                    Uaprox = U(:,nodes(1)) + 0.5 * Ugrad * distance; % Используем формулу Тейлора : U(X) = U(0) + \nabla(U)/\partial(X) * \Delta X
                    U(:,nodes(j)) = U(:,nodes(j)) + w * Uaprox; % 
                end
            end
            U(bc) = 0;
        end

        function v = volume(obj,nodeCoords) 
           tetraedron = [1 3 6 8; 1 2 6 3; 1 3 8 4; 1 6 5 8; 3 6 8 7]; % Разбиваем куб на пять тетраэдров
           determinant = arrayfun(@(i) det([nodeCoords(:,tetraedron(i,:)); ones(1,4)]), 1:size(tetraedron,1)); % Вычисляем их объёмы
           v = 1/6 * sum(determinant); % Складываем
        end
        
        function [grad,detJ] =  computeGradient(obj,xi,nodeCoords)
            v1 = nodeCoords(:,3) - nodeCoords(:,1);
            v2 = nodeCoords(:,6) - nodeCoords(:,1);
            v3 = nodeCoords(:,8) - nodeCoords(:,1);
            
            grad = zeros(3,8);
            detJ = obj.volume(nodeCoords);
            r = cross([v3,v1,v2],[v2,v3,v1]) / detJ;
            r = [ -sum(r,2),r];
            grad(:,[1,3,6,8]) = r;
            detJ = detJ/32;
        end
    end
end
