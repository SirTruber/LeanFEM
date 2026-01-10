% Решатель динамических задач методом Хуболта(Неявная)
classdef Hulbot < Static
    properties
        % Состояние системы
        time_step   % Временной шаг             (Число)
        t = 0       % Текущее время             (Число)
        % Матрицы системы
        M           % Матрица масс              (sparse)
        % Результат счёта
        U           % Узловые перемещения       [Nx1]
        U_prev      % Узловые перемещения       [Nx3]
    end
    methods
        function obj = Hulbot(dt, constraint, stiffness, mass, V0, loads)
            obj = obj@Static(constraint,stiffness);
            obj.time_step = dt;

            n = size(obj.K,1);
            if isempty(V0)
                V = zeros(n, 1);
            else
                V = V0;
            end
            if isempty(loads)
                A = zeros(n, 1);
            else
                A = mass \ loads(:);
            end
            obj.U_prev = zeros(n, 3);
            obj.U_prev(:,2) = - dt * (V - dt * A);

            obj.M = mass;
            obj.M(constraint.nodes,:) = 0;
            obj.M(:,constraint.nodes) = 0;

            K = 6/dt/dt * obj.M + obj.K;

            r = loads(:) + 2*obj.M * (3/dt * V  + A);
            obj.U = K\r;

            obj.K = chol(obj.K + 2/obj.time_step / obj.time_step * obj.M);

        end

        function step(obj,force)
            persistent count;
            if isempty(count)
                count = 1;
            end
            count = count + 1;
            obj.t = obj.time_step * count;

            obj.U_prev = [obj.U ,obj.U_prev(:,[1,2])];

            r = force(:) + 1/obj.time_step / obj.time_step * obj.M * (5 * obj.U_prev(:,1) - 4 * obj.U_prev(:,2) + obj.U_prev(:,3));

            r(obj.attach.nodes) = obj.attach.values;

            obj.U = obj.K\(obj.K'\r);
        end
        function ret = A(obj)
            ret = 1/obj.time_step/obj.time_step * (2*obj.U - 5*obj.U_prev(:,1) + 4*obj.U_prev(:,2) - obj.U_prev(:,3));
        end
        function ret = V(obj)
            ret = 1/obj.time_step/6 * (11 * obj.U - 18 * obj.U_prev(:,1) + 9 * obj.U_prev(:,2) - 2 * obj.U_prev(:,3));
        end
    end
end
