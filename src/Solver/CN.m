% Решатель динамических задач методом Кранка-Николсон(линейное ускорение в интервале времени)
classdef CN < Static
    properties
        % Состояние системы
        time_step   % Временной шаг             (Число)
        t = 0       % Текущее время             (Число)
        attach      % Данные закрепления        (ConstraintData)
        % Матрицы системы
        M           % Матрица масс              (sparse)
        % Результат счёта
        V           % Узловые скорости          [Nx1]
        A           % Узловые ускорения         [Nx1]

        U_prev      % Узловые перемещения       [Nx1]
        V_prev      % Узловые скорости          [Nx1]
        A_prev      % Узловые ускорения         [Nx1]
        F_prev
    end
    methods
%         function obj = CN(dt, constraint, stiffness, mass, V0, loads)
%             obj = obj@Static(constraint,stiffness);
%
%             obj.time_step = dt;
%
%             n = size(obj.K,1);
%
%             if isempty(V0)
%                 obj.V = zeros(n, 1);
%             else
%                 obj.V = V0;
%             end
%             obj.A = zeros(n,1);
%             obj.U_prev = zeros(n, 1);
%             obj.V_prev = zeros(n, 1);
%
%             obj.F_prev = loads;
%
%             obj.M = mass;
%             obj.M(constraint.nodes,:) = 0;
%             obj.M(:,constraint.nodes) = 0;
%
%             obj.K = chol( obj.K + 4/dt/dt * obj.M);
%         end
%
%         function step(obj,force)
%             persistent count;
%             if isempty(count)
%                 count = 0;
%             end
%             count = count + 1;
%             obj.t = obj.time_step * count;
%
%             obj.U_prev = obj.U;
%             obj.V_prev = obj.V;
%             obj.A_prev = obj.A;
%
%             r = force.'(:) + obj.M * (4/(obj.time_step * obj.time_step) * obj.U + 4/ (obj.time_step) * obj.V + obj.A);
%             r(obj.attach.nodes) = obj.attach.values;
%
%             obj.U = obj.K\(obj.K'\r);
%             obj.V = 2 / obj.time_step * (obj.U - obj.U_prev) - obj.V_prev;
%             obj.A = 4 / obj.time_step / obj.time_step * (obj.U - obj.U_prev) - 4/ obj.time_step * obj.V_prev - obj.A_prev;
%         end
        function obj = CN(dt, constraint, stiffness, mass, V0, loads)
            obj = obj@Static(constraint,stiffness);

            obj.time_step = dt;

            n = size(obj.K,1);

            if isempty(V0)
                obj.V = zeros(n, 1);
            else
                obj.V = V0;
            end
            obj.U_prev = zeros(n, 1);
            obj.V_prev = zeros(n, 1);

            obj.F_prev = loads;

            obj.M = mass;
            obj.M(constraint.nodes,:) = 0;
            obj.M(:,constraint.nodes) = 0;

            obj.K = chol(dt * obj.K + 4/dt * obj.M);
        end

        function step(obj,force)
            persistent count;
            if isempty(count)
                count = 0;
            end
            count = count + 1;
            obj.t = obj.time_step * count;

            obj.U_prev = obj.U;
            obj.V_prev = obj.V;

            r = 2 * (force.'(:) + obj.F_prev)  + (obj.M * 4/obj.time_step  - obj.time_step * obj.K) * obj.V_prev  - 4 * obj.K * obj.U_prev; %Силы с двух шагов
            r(obj.attach.nodes) = obj.attach.values;

            obj.V = obj.K\(obj.K'\r);
            obj.U = obj.U_prev + 0.5 * obj.time_step * (obj.V + obj.V_prev);
            obj.F_prev = force.'(:);
        end
    end
end
