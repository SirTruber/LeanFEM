% Решатель линейных статических задач
classdef Static < handle
    properties
        % Сборщик глобальных матриц
        assembler
        % Состояние системы
        dofIndices      % Закреплённые степени свободы
        dofValues       % Заданные перемещения, обычно нулевые
        % Матрицы системы
        K           % Исходная матрица жесткости (sparse)
        Keff        % Эффективная матрица жесткости (sparse)
        % Результат счёта
        U           % Узловые перемещения           [Nx1]
    end
    methods
        function obj = Static(assembler)
            obj.assembler = assembler;
            obj.K = assembler.stiffness();
            obj.U = [];
        end

        function applyBC(obj, dofIndices, dofValues)
            obj.dofIndices = dofIndices(:);

            if nargin < 3 || isempty(dofValues)
                obj.dofValues = zeros(numel(dofIndices), 1);
            else
                obj.dofValues = dofValues(:);
            end

            obj.Keff = obj.K;
            obj.Keff(obj.dofIndices,:) = 0;
            obj.Keff(:,obj.dofIndices) = 0;
            obj.Keff(sub2ind(size(obj.K),obj.dofIndices,obj.dofIndices)) = 1;
        end

        function step(obj,force)
            F = force(:) - obj.K(:,obj.dofIndices) * obj.dofValues; % Корректируем правую часть с учётом граничных условий
            F(obj.dofIndices) = obj.dofValues; % Применяем граничные условия первого рода

            obj.U = obj.Keff \ F; % Решаем СЛАУ (обычно симметрично)
        end
    end
end
