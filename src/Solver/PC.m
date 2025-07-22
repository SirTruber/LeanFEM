% Решатель динамических задач методом предиктор-корректор(Полуявная)
classdef PC < Static
    properties
        % Состояние системы
        time_step   % Временной шаг                 (Число)
        t = 0       % Текущее время                 (Число)
        attach      % Данные закрепления            (ConstraintData)
        % Матрицы системы
        M           % Матрица масс                  (sparse)
        K           % Эффективная матрица жесткости (sparse)
        % Результат счёта
        U           % Узловые перемещения           [Nx1]
        V
        A           % Узловые ускорения             [Nx1]
    end
    methods
        function obj = PC(dt, constraint, stiffness, mass, V0, loads)
            obj = obj@Static(constraint,stiffness);

            obj.time_step = dt;
            obj.M = mass; % Предполагаем диагональность матрицы

            n = size(obj.K,1);
            if isempty(V0)
                obj.V = zeros(n, 1);
            else
                obj.V = V0;
            end
            if isempty(loads)
                obj.A = zeros(n, 1);
            else
                obj.A = obj.M \ loads.'(:);
            end
            obj.U = zeros(n,1);
        end

        function step(obj,force)
            persistent count;
            if isempty(count)
                count = 0;
            end
            count = count + 1;
            obj.t = obj.time_step * count;

            %Предиктор
            A_next = obj.M\(force.'(:) - obj.K*obj.U);

            U_next = obj.U + obj.time_step * obj.V + 0.5 * obj.time_step ^ 2 * A_next;
            V_next = obj.V + obj.time_step * A_next;

            U_next(obj.attach.nodes,:) = obj.attach.values;
            V_next(obj.attach.nodes,:) = 0;
            %Корректор

            obj.A = obj.M\(force.'(:) - obj.K*U_next);

            obj.V = obj.V + 0.5 * obj.time_step * (A_next + obj.A);
            obj.U = obj.U + 0.5 * obj.time_step * (V_next + obj.V);

            obj.U(obj.attach.nodes,:) = obj.attach.values;
            obj.V(obj.attach.nodes,:) = 0;

        end
    end
end
