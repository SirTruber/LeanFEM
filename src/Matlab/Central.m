% Решатель динамических задач методом центральных разностей
classdef Central < handle
    properties
        % Состояние системы
        coeffs      % Постоянные интегрирования [3x1]
        time_step   % Временной шаг             (Число)
        count = 0
        t = 0       % Текущее время             (Число)
        fixed      % Данные закрепления        (ConstraintData)
        % Матрицы системы
        M           % Матрица масс              (sparse)
        K           % Матрица жесткости         (sparse)
    end
    methods
        function UU = IC(this,U0,V0,A0)
            U_prev = U0 - this.time_step * V0 + 0.5 * this.time_step^2 * A0;
            UU = [U0,U_prev];
        end

        function setParam(this,dt)
            this.time_step = dt;

            this.coeffs = [1/dt^2; ...
                           0.5/dt; ...
                          2/dt^2];
        end

        function assemble(this, element, geometry)
            [this.K,this.M] = element.assemble(geometry);

        end

        function constrain(this, fixed, moved)
            this.fixed = fixed;
            toZero = [fixed;moved];

            this.K(toZero,:) = 0;
            this.K(:,fixed) = 0;
            this.K(sub2ind(size(this.K),toZero,toZero)) = 1;

            this.M(toZero,:) = 0;
            this.M(:,fixed) = 0;
            this.M(sub2ind(size(this.K),toZero,toZero)) = 1;
        end

        function nextUU = step(this, UU, force)
            U_prev = UU(:,2);
            U = UU(:,1);

            q_eff = force + this.M * ( this.coeffs(3) * U - this.coeffs(1) * U_prev) - this.K * U ;
            q_eff(this.fixed) = 0;

            U_next = this.time_step^2 * (this.M\q_eff);
%             A = obj.coeffs(1) * (U_next - 2*U + U_prev);
%             V = this.coeffs(2) * (U_next-U_prev);

            this.count += 1;
            this.t = this.time_step * this.count;

            nextUU = [U_next,U];
        end
    end
end
