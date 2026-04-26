% Решатель динамических задач методом центральных разностей(Явный)
classdef Cross < handle
    properties
        % Сборщик глобальных матриц
        assembler
        % Состояние системы
        dofIndices  % Закреплённые степени свободы
        dofValues   % Заданные перемещения, обычно нулевые
        dt          % Временной шаг             (Число)
        % Матрицы системы
        M           % Матрица масс              (sparse)
        K           % Матрица жесткости         (sparse)
        Keff        % Эффективная матрица жесткости (sparse)
        % Результат счёта
        U           % Узловые перемещения       [Nx1]
        V           % Узловые скорости          [Nx1]
        A           % Узловые ускорения         [Nx1]
    end
    methods
        function obj = Cross(dt, assembler)
            obj.dt = dt;
            obj.assembler = assembler;
            obj.K = assembler.stiffness();
            obj.M = assembler.mass();
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

        function applyIC(obj, U0, V0, F0)
            U0(obj.dofIndices) = obj.dofValues;
            V0(obj.dofIndices) = 0;

            A0 = obj.M \ (F0(:) - obj.K * U0);
            A0(obj.dofIndices) = 0;

            obj.U = U0;
            obj.V = V0;
            obj.A = A0;

            %Первый шаг
            obj.V = obj.V + 0.5 * dt * obj.A;
            obj.U = obj.U + dt * obj.V;
        end

        function step(obj,force)
            F = force(:) - obj.Keff * obj.U; % Эффективная правая часть
            F = F - obj.K(:,obj.dofIndices) * obj.dofValues; % Корректируем правую часть с учётом граничных условий
            F(obj.dofIndices) = obj.dofValues; % Применяем граничные условия первого рода

            obj.A = obj.M\F;
            obj.V = obj.V + obj.dt * obj.A;
            obj.U = obj.U + obj.dt * obj.V;

            obj.U(obj.dofIndices) = obj.dofValues;
            obj.V(obj.dofIndices) = 0;
            obj.A(obj.dofIndices) = 0;
        end
    end
end
