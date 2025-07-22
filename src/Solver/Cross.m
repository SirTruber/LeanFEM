% Решатель динамических задач методом центральных разностей(Явный)
classdef Cross < Static
    properties
        % Состояние системы
        time_step   % Временной шаг             (Число)
        t = 0       % Текущее время             (Число)
        % Матрицы системы
        M           % Матрица масс              (sparse)
        M_ef        % Матрица масс(эффективная) (sparse)
        % Результат счёта
        U           % Узловые перемещения       [Nx1]
        V           % Узловые скорости          [Nx1]
        A           % Узловые ускорения         [Nx1]
    end
    methods
        function obj = Cross(dt, constraint, stiffness, mass, V0, loads)
            obj = obj@Static(constraint,stiffness);
            obj.time_step = dt;


            obj.M = mass;
            n = size(obj.K,1);

            if isempty(V0)
                obj.V = zeros(n, 1);
            else
                obj.V = V0;
%                 obj.U = obj.U + dt * obj.V;
            end
%             if isempty(loads)

            obj.U = zeros(n, 1);
%             obj.A = zeros(n, 1);
%             obj.U_prev = zeros(n, 2);
%             else
            obj.A = obj.M \ loads.'(:);
%             end
            % Первый шаг
            obj.V = obj.V + 0.5 * dt * obj.A;
            obj.U = obj.U + dt * obj.V;
%             obj.U_prev(:,1) = obj.U_prev(:,1) - dt * obj.V + 0.5 * dt * dt * obj.A;

        end

        function step(obj,force)
            persistent count;
            if isempty(count)
                count = 0;
            end
            count = count + 1;
            obj.t = obj.time_step * count;

%             obj.U_prev = [obj.U, obj.U_prev(:,1)];
%             disp(size(obj.U_prev));
%             r = force.'(:) - obj.K * obj.U_prev(:,1) + obj.time_step * obj.time_step * obj.M * (2 * obj.U_prev(:,1) - obj.U_prev(:,2));
%             obj.U = obj.M_ef\(obj.M_ef'\r);
            r = force.'(:) - obj.K * obj.U;
            obj.A = obj.M\r;
            obj.V = obj.V + obj.time_step * obj.A;
            obj.U = obj.U + obj.time_step * obj.V;


            obj.U(obj.attach.nodes,:) = obj.attach.values;
            obj.V(obj.attach.nodes,:) = 0;
        end
    end
end
