% Решатель динамических задач методом Хуболта(Неявная)
classdef Hulbot < handle
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
        U, U_prev
        V_prev, A_prev
    end
    methods
        function obj = Hulbot(dt, assembler)
            obj.dt        = dt;
            obj.assembler = assembler;
            obj.K         = assembler.stiffness();
            M_full        = assembler.mass();
            diag_M        = sum(M_full, 2);
            obj.M         = spdiags(diag_M, 0, size(M_full,1), size(M_full,2));
        end

        function applyBC(obj, idx, val)
            obj.dofIndices = idx(:);
            if nargin < 3 || isempty(val)
                obj.dofValues = zeros(numel(idx), 1);
            else
                obj.dofValues = val(:);
            end

            c0 = 6 / obj.dt^2;
            obj.Keff = obj.K + c0 * obj.M;

            obj.L = obj.Keff;
            obj.L(obj.dofIndices,:) = 0;
            obj.L(:,obj.dofIndices) = 0;
            obj.L(sub2ind(size(obj.Keff), obj.dofIndices, obj.dofIndices)) = 1;
            obj.L = chol(obj.L);
        end

        function applyIC(obj, U0, V0, F0)
            U0 = U0(:);  V0 = V0(:);  F0 = F0(:);
            U0(obj.dofIndices) = obj.dofValues;
            V0(obj.dofIndices) = 0;

            A0 = obj.M \ (F0 - obj.K * U0);
            A0(obj.dofIndices) = 0;

            % первый шаг назад, чтобы получить «фиктивное» U_{-1}
            obj.U      = U0;
            obj.U_prev = U0 - obj.dt * V0 + 0.5 * obj.dt^2 * A0;
            obj.V_prev = V0;
            obj.A_prev = A0;
        end

        function step(obj, force)
            F = force(:);
            c0 = 1 / obj.dt^2;
            c1 = 4 * c0 * obj.dt;    % = 4/dt
            c2 = 5 * c0;             % = 5/dt²

            % линейное ускорение в интервале
            F = F + obj.M * (c2 * obj.U + c0 * obj.U_prev);
            F = F - obj.Keff(:, obj.dofIndices) * obj.dofValues;
            F(obj.dofIndices) = obj.dofValues;

            obj.U = obj.L \ (obj.L' \ F);

            % восстановить A, V (при желании)
            % A = c0*(2U - 5U_prev + 4U_prev2 - U_prev3);
            % V = 1/(6dt)*(11U - 18U_prev + 9U_prev2 - 2U_prev3);
        end
    end
end