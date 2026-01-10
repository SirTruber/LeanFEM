% Решатель динамических задач методом центральных разностей(Явный)
classdef Cross < Static
    properties
        % Состояние системы
        time_step   % Временной шаг             (Число)
        t = 0       % Текущее время             (Число)
        % Матрицы системы
        C
        M           % Матрица масс              (sparse)
        M_ef        % Матрица масс(эффективная) (sparse)
        % Результат счёта
        V           % Узловые скорости          [Nx1]
        A           % Узловые ускорения         [Nx1]
    end
    methods
        function obj = Cross(dt, constraint, stiffness, mass, V0)
            obj = obj@Static(constraint,stiffness);
            obj.time_step = dt;
            obj.M = mass;
            %obj.C = 0.005/dt * mass;
            n = size(obj.K,1);

            if isempty(V0)
                obj.V = zeros(n, 1);
            else
                obj.V = V0;
%                 obj.U = obj.U + dt * obj.V;
            end

            obj.U = zeros(n, 1);
             obj.A = zeros(n, 1);
%             obj.U_prev = zeros(n, 2);
%             else
%            obj.A = obj.M \ loads.'(:);
%             end
            % Первый шаг
            obj.V = obj.V + 0.5 * dt * obj.A;
            obj.U = obj.U + dt * obj.V;
%             obj.U_prev(:,1) = obj.U_prev(:,1) - dt * obj.V + 0.5 * dt * dt * obj.A;

        end

        function step(obj,force)
            obj.t = obj.t + obj.time_step;

%             obj.U_prev = [obj.U, obj.U_prev(:,1)];
%             disp(size(obj.U_prev));
%             r = force(:) - obj.K * obj.U_prev(:,1) + obj.time_step * obj.time_step * obj.M * (2 * obj.U_prev(:,1) - obj.U_prev(:,2));
%             obj.U = obj.M_ef\(obj.M_ef'\r);
            r = force(:) - obj.K * obj.U; %- obj.C * obj.V;
            obj.A = obj.M\r;
            obj.V = obj.V + obj.time_step * obj.A;
            obj.U = obj.U + obj.time_step * obj.V;

            obj.U(obj.attach,:) = 0;
            obj.V(obj.attach,:) = 0;
        end
    end
end
