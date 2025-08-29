% Решатель линейных статических задач
classdef Static < handle
    properties
        % Состояние системы
        attach      % Данные закрепления            (ConstraintData)
        % Матрицы системы
        K           % Эффективная матрица жесткости (sparse)
        % Результат счёта
        U           % Узловые перемещения           [Nx1]
    end
    methods
        function obj = Static(constraint, stiffness)
            obj.attach = constraint;

            obj.K = stiffness;

            obj.K(constraint.nodes,:) = 0;
            obj.K(:,constraint.nodes) = 0;
            obj.K(sub2ind(size(obj.K),constraint.nodes,constraint.nodes)) = 1;

            obj.U = zeros(size(obj.K,1),1);
        end

        function step(obj,force)
        q = force.'(:);
        q(obj.attach.nodes) = obj.attach.values;

        obj.U = obj.K \ q;
        end
    end
end
