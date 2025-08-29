% Решатель динамических задач методом Ньюмарка(линейное ускорение в интервале времени)
classdef Newmark < Static
    properties (Constant)
        b = 0.5    % Параметр демпфирования (0.5 для усреднения) >= 0.5
        a = 0.25   % Параметр устойчивости (0.25 для неявной схемы) >=  0.25 * (0.5 + beta)^2
    end
    properties
        % Состояние системы
        coeffs      % Постоянные интегрирования [8x1]
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
    end
    methods
        function obj = Newmark(dt, constraint, stiffness, mass, V0, loads)
            obj = obj@Static(constraint,stiffness);
            obj.coeffs = [ 1/obj.a/dt^2; ...
                         obj.b/obj.a/dt; ...
                             1/obj.a/dt; ...
                          0.5/obj.a - 1; ...
                        obj.b/obj.a - 1; ...
           0.5 * dt * (obj.b/obj.a - 2); ...
                       dt * (1 - obj.b); ...
                              obj.b*dt];

            obj.time_step = dt;

            n = size(obj.K,1);

            obj.A = zeros(n, 1);
            if isempty(V0)
                obj.V = zeros(n, 1);
            else
                obj.V = V0;
            end
%             if isempty(loads)
%             else
%                 obj.A = mass \ loads.'(:);
            obj.U_prev = zeros(n, 1);
            obj.V_prev = zeros(n, 1);
            obj.A_prev = zeros(n, 1);

            obj.M = mass;
            obj.M(constraint.nodes,:) = 0;
            obj.M(:,constraint.nodes) = 0;

            obj.K = chol(obj.K + obj.coeffs(1) * obj.M);
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
            obj.A_prev = obj.A;

            r = force.'(:) + obj.M * (obj.coeffs(1) * obj.U_prev + obj.coeffs(3) * obj.V_prev + obj.coeffs(4) * obj.A_prev);
            r(obj.attach.nodes) = obj.attach.values;

            obj.U = obj.K\(obj.K'\r);
            obj.A = obj.coeffs(1) * (obj.U - obj.U_prev) - obj.coeffs(3) * obj.V_prev - obj.coeffs(4) * obj.A_prev;
            obj.V = obj.V_prev + obj.coeffs(7) * obj.A_prev + obj.coeffs(8) * obj.A;
        end
    end
end
