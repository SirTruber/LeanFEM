classdef Elasticity3D < Element % Класс 3D упругости для гексаэдров
    properties
        numDIM = 3;
        material % Материал элемента
        elasticity % Матрица упругих постоянных(симметричная, положительно определённая)
    end
    methods
        function obj = Elasticity3D(material,nquad)
            obj = obj@Element(nquad);
            obj.material = material;
            obj.elasticity = blkdiag(material.firstLame(ones(3)) + 2 * material.secondLame * eye(3), material.secondLame * eye(3));
        end

        function K = stiffness(obj,nodeCoords)
            K = zeros(obj.numDOF); 
            n = numel(obj.gaussP);
            for i = 1 : n
                for j = 1 : n
                    for k = 1 : n
                        intPoint = obj.gaussP([i,j,k]); % координаты точки интегрирования
                        [grad,detJ] = obj.computeGradient(intPoint,nodeCoords); % Вычисляем градиенты и якобиан в точке интегрирования
                        B = obj.gradMatrix(grad); % Вычисляем градиентную матрицу ( связь деформаций и перемещений)
                        G = B' * obj.elasticity * B * detJ; % Вычисляем значение подынтегральной функции
                        
                        w = prod(obj.gaussW([i,j,k])); % Вычисляем вес точки интегрирования
                        K = K + w * G; % Добавляем к общему интегралу, умножив на вес
                    end
                end
            end
        end

        function M = mass(obj,nodeCoords)
            M = obj.volume(nodeCoords) * obj.material.density * eye(obj.numDOF) / obj.numDOF; % Матрица масс принимается сосредоточенной в узлах (без связи между узлами)
        end

        function B = gradMatrix(obj,grad)
            n = obj.numDOF;
            p = obj.numDIM;
            B = zeros(6, n);

            B(1,1:p:n) = grad(1,:); %εxx
            B(2,2:p:n) = grad(2,:); %εyy
            B(3,3:p:n) = grad(3,:); %εzz

            B(4,1:p:n) = grad(2,:); %γxy
            B(4,2:p:n) = grad(1,:); %γyx

            B(5,2:p:n) = grad(3,:); %γyz
            B(5,3:p:n) = grad(2,:); %γzy

            B(6,1:p:n) = grad(3,:); %γxz
            B(6,3:p:n) = grad(1,:); %γzx
        end
        
        function [strain,stress] = evaluateStrainAndStress(obj, grid, U) % Вычисляет значение деформаций и напряжений в узлах
            numNodes = grid.numNodes();  % Число узлов
            numEl = grid.numElements();  % Число ячеек

            strain = zeros(6,numNodes);  % Значения деформаций в узлах
            stress = zeros(6,numNodes);  % Значения напряжений в узлах

            intPoint = [ 1,-1,-1;...
                 1, 1,-1;...
                -1, 1,-1;...
                -1,-1,-1;...
                 1,-1, 1;...
                 1, 1, 1;...
                -1, 1, 1;...
                -1,-1, 1]'; % Локальные координаты, в которых вычисляются производные
            weight = zeros(1,numNodes);
            for i = 1:numEl % Для каждой ячейки:
                nodes = grid.elements(i); % Достаём номера узлов элемента
                points = grid.points(i); % Достаём координаты узлов элемента
                volume = obj.volume(points); 
                weight(nodes) = weight(nodes) + volume;
                Ue = U(:,nodes); % Достаём перемещения узлов ячейки
                for j = 1:numel(nodes) % Для каждого узла в ячейке:
                    grad = obj.computeGradient(intPoint(:,j),points); % Вычисляем производные в локальных координатах
                    B = obj.gradMatrix(grad); % Вычисляем градиентную матрицу                     
                    strainEl = B * Ue(:); % Вычисляем деформации в этой точке
                    stressEl = obj.elasticity * strainEl; % Вычисляем производные в этой точке
                    strain(:,nodes(j)) = strain(:,nodes(j)) + volume * strainEl(1:6); % Добавляем деформации к узловым значениям, предварительно умножив на вес
            stress(:,nodes(j)) = stress(:,nodes(j)) + volume * stressEl(1:6); % Добавляем напряжения к узловым значениям, предварительно умножив на вес
                end
            end
            strain = strain./weight; % Берем средне взвешенное, где вес пропорционален ...
            stress = stress./weight; % объёму ячейки s = sum(si*wi/sum(wi))
            stress = 1e5 * stress; % Возвращаем напряжения в МПа
        end

        function vM = vonMises(obj,stress) % Вычисляет эквивалентное напряжение Фон Мизеса
            vM = sqrt(0.5 * ((stress(1,:) - stress(2,:)).^2 + (stress(2,:) - stress(3,:)).^2 + (stress(3,:) - stress(1,:)).^2 + 6 * (stress(4,:).^2 + stress(5,:).^2 + stress(6,:).^2)));
        end  

        function v = volume(obj,nodeCoords)
            v = 8 * det(obj.jacobian([0,0,0],nodeCoords)); % Одноточечное интегрирование объёма по Гауссу
        end

        %function v = volume(obj,nodeCoords) 
        %    tetraedron = [1 3 6 8; 1 2 6 3; 1 3 8 4; 1 6 5 8; 3 6 8 7]; % Разбиваем куб на пять тетраэдров
        %    determinant = arrayfun(@(i) det([nodeCoords(:,tetraedron(i,:)); ones(1,4)]), 1:size(tetraedron,1)); % Вычисляем их объёмы
        %    v = 1/6 * sum(determinant); % Складываем
        %end

        function h = minHeight(obj,nodeCoords)
            edges = [1 2; 2 3; 3 4; 4 1; 5 6; 6 7; 7 8; 8 5; 1 5; 2 6; 3 7; 4 8]; % Номера узлов, образующих рёбра куба

            edges = nodeCoords(:,edges(:,2)) - nodeCoords(:,edges(:,1)); % Вектора, образующие рёбра куба
            len = sqrt(sum(edges.^2,2)); % Длина рёбер
            h = min(nonzeros(len)); % Длинна самого короткого ребра
        end
    end
end
