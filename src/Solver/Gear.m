% Решатель динамических задач методом Гира(Неявная)
classdef Gear < Static
    properties
        % Состояние системы
        time_step   % Временной шаг             (Число)
        t = 0       % Текущее время             (Число)
        % Матрицы системы
        M           % Матрица масс              (sparse)
        % Результат счёта
        U           % Узловые перемещения       [Nx1]
        V           % Узловые скорости          [Nx1]
        U_prev      % Узловые перемещения       [Nx2]
        V_prev      % Узловые скорости          [Nx2]
    end
    methods
        function obj = Gear(dt, constraint, stiffness, mass, V0, loads)
            obj = obj@Static(constraint,stiffness);
            obj.time_step = dt;

            n = size(obj.K,1);
            if isempty(V0)
                obj.V = zeros(n, 1);
            else
                obj.V = V0;
            end
            if isempty(loads)
                A = zeros(n, 1);
            else
                A = mass \ loads.'(:);
            end
            obj.U_prev = zeros(n, 2);
            obj.V_prev = zeros(n, 2);

            obj.V_prev(:,1) = obj.V - dt * A;
            obj.U_prev(:,1) = - dt * obj.V_prev(:,1);

            obj.M = mass;
            obj.M(constraint.nodes,:) = 0;
            obj.M(:,constraint.nodes) = 0;

            obj.K = chol(3/2 / dt * obj.M + 2*dt/3 * obj.K);
        end

        function step(obj,force)
            persistent count;
            if isempty(count)
                count = 0;
            end
            count = count + 1;
            obj.t = obj.time_step * count;

            obj.U_prev = [obj.U,obj.U_prev(:,1)];
            obj.V_prev = [obj.V,obj.V_prev(:,1)];

            r = 2/3 * obj.time_step * force.'(:) + obj.M * (2/obj.time_step * obj.U_prev(:,1) - 0.5/obj.time_step * obj.U_prev(:,2) + 4/3 * obj.V_prev(:,1) - 1/3 * obj.V_prev(:,2));

            r(obj.attach.nodes) = obj.attach.values;

            obj.U = obj.K\(obj.K'\r);
            obj.V = 1/obj.time_step * (3/2*obj.U - 2*obj.U_prev(:,1) + 0.5*obj.U_prev(:,2));
        end
        function ret = A(obj)
            ret = 1/obj.time_step * (3/2*obj.V - 2*obj.V_prev(:,1) + 0.5*obj.V_prev(:,2));
        end
    end
end
