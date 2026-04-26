% Решатель динамических задач методом Ньюмарка(линейное ускорение в интервале времени)
classdef Newmark < handle
    properties (Constant)
        gamma = 0.5 % Параметр демпфирования (0.5 для усреднения) >= 0.5
        beta = 0.25 % Параметр устойчивости (0.25 для неявной схемы) >=  0.25 * (0.5 + gamma)^2
    end
    properties
        % Сборщик глобальных матриц
        assembler
        % Состояние системы
        dofIndices  % Закреплённые степени свободы
        dofValues   % Заданные перемещения, обычно нулевые
        dt          % Временной шаг             (Число)
        % Матрицы системы
        M           % Матрица масс              (sparse)
        K           % Исходная матрица жесткости (sparse)
        Keff        % Эффективная матрица жесткости (sparse)
        L           % Факторизованная матрица системы (sparse)
        % Результат счёта
        U           % Узловые перемещения       [Nx1]
        V           % Узловые скорости          [Nx1]
        A           % Узловые ускорения         [Nx1]

        U_prev      % Узловые перемещения       [Nx1]
        V_prev      % Узловые скорости          [Nx1]
        A_prev      % Узловые ускорения         [Nx1]
    end
    methods
        function obj = Newmark(dt, assembler)
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

            c0 = 1 / (obj.beta * obj.dt^2);
            obj.Keff = obj.K + c0 * obj.M;

            obj.L = obj.Keff;
            obj.L(obj.dofIndices,:) = 0;
            obj.L(:,obj.dofIndices) = 0;
            obj.L(sub2ind(size(obj.K),obj.dofIndices,obj.dofIndices)) = 1;
            obj.L = chol(obj.L);
        end

        function applyIC(obj, U0, V0, F0)
            U0(obj.dofIndices) = obj.dofValues;
            V0(obj.dofIndices) = 0;

            A0 = obj.M \ (F0(:) - obj.K * U0);
            A0(obj.dofIndices) = 0;

            obj.U = U0;
            obj.V = V0;
            obj.A = A0;
        end

        function step(obj,force)
            obj.U_prev = obj.U;
            obj.V_prev = obj.V;
            obj.A_prev = obj.A;

            c0 = 1 / (obj.beta * obj.dt^2);
            c1 = obj.dt * c0;
            c2 = 0.5 / obj.beta - 1;

            F = force(:) + obj.M * (c0 * obj.U_prev + c1 * obj.V_prev + c2 * obj.A_prev); % Эффективная правая часть
            F = F - obj.Keff(:,obj.dofIndices) * obj.dofValues; % Корректируем правую часть с учётом граничных условий
            F(obj.dofIndices) = obj.dofValues; % Применяем граничные условия первого рода

            obj.U = obj.L\(obj.L'\F);
            obj.A = c0 * (obj.U - obj.U_prev) - c1 * obj.V_prev - c2 * obj.A_prev;
            obj.V = obj.V_prev + obj.dt * ( obj.gamma * obj.A + (1 - obj.gamma) * obj.A_prev);

            obj.U(obj.dofIndices) = obj.dofValues;
            obj.V(obj.dofIndices) = 0;
            obj.A(obj.dofIndices) = 0;
        end
    end
end
