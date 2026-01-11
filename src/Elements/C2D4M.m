classdef C2D4M < C2D4
    properties
        param = 1.0 % Параметр моментной схемы, большие значения соответствуют меньшему контролю над hourglass модами. При решении задач динамики по явной схеме, не стоит ставить меньше 1 в силу CFL условия
    end
    methods
        function obj = C2D4M(material)
            obj@C2D4(material,1);
        end

        function K = stiffness(obj,nodeCoords)
            [grad,gamma] = obj.computeGradient([0;0],nodeCoords); % Вычисляем градиенты в любой точке (они постоянны во всём элементе)
            
            B = obj.gradMatrix(grad); % Вычисляем градиентную матрицу
            K = (B' * obj.elasticity * B  + obj.material.secondLame * kron(gamma'*gamma,eye(obj.numDIM))) * obj.volume(nodeCoords); % Интегрируем по объему, добавляем жёсткость в направлении hourglass мод
        end

        function [grad,gamma] =  computeGradient(obj,xi,nodeCoords)

            h = obj.param * obj.minHeight(nodeCoords); % Находим размер по дополнительному измерению

            imaginary = [ 0  h  0  h];
            J = [ones(1,4); nodeCoords; imaginary]; % Находим матрицу Якоби с дополнительными размерностями
            d = inv(J'); % В силу линейности функции, матрица градиентов функций формы - единичная, на неё можно не домножать
            grad = d(2:3,:); % В первой строке хранятся значения функции формы, в 2-3 - производные по ним,
            gamma = d(4,:);  % в 4 вектор контроля hourglass мод
        end
    end
end
