% Решатель линейных статических задач
classdef Static < handle
    properties
        % Состояние системы
        attach      % Данные закрепления            
        % Матрицы системы
        K           % Эффективная матрица жесткости (sparse)
        % Результат счёта
        U           % Узловые перемещения           [Nx1]
    end
    methods
        function obj = Static(constraint, stiffness)
            obj.attach = constraint;

            obj.K = stiffness;

            obj.K(constraint,:) = 0; % Применяем граничные условия первого рода u = 0
            obj.K(:,constraint) = 0;
            obj.K(sub2ind(size(obj.K),constraint,constraint)) = 1;

            obj.U = zeros(size(obj.K,1),1); % Инициализируем вектор перемещений нулями
        end

        function step(obj,force)
            q = force(:);
            q(obj.attach) = 0; % Применяем граничные условия первого рода u = 0

            obj.U = obj.K \ q; % Решаем СЛАУ (обычно симметрично)
        end
    end
end
