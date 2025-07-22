% Решатель динамических задач методом Адамса-Башфорта(Явная)
classdef AdBash < Static
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
        V           % Узловые скорости              [Nx1]
        A
        A_prev
        V_prev      % Узловые перемещения           [Nx1]
    end
    methods
        function obj = AdBash(dt, constraint, stiffness, mass, V0, loads)
            obj = obj@Static(constraint,stiffness);

            obj.time_step = dt;
            obj.M = mass;

            n = size(obj.K,1);

            obj.U = zeros(n,1);
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

            %Первый шаг
            obj.A_prev = obj.A;
            obj.V_prev = obj.V;

            obj.V = obj.V + dt * obj.A;
            obj.U = obj.U + dt * obj.V;
        end

        function step(obj,force)
            persistent count;
            if isempty(count)
                count = 0;
            end
            count = count + 1;
            obj.t = obj.time_step * count;

            r = force.'(:) - obj.K * obj.U;

            obj.A = obj.M\r;

            obj.V = obj.V + obj.time_step * (1.5 * obj.A - 0.5 * obj.A_prev);
            obj.U = obj.U + obj.time_step * (1.5 * obj.V - 0.5 * obj.V_prev);

            obj.U(obj.attach.nodes,:) = obj.attach.values;
            obj.V(obj.attach.nodes,:) = 0;

            obj.A_prev = obj.A;
            obj.V_prev = obj.V;
        end
    end
end
