% Решатель динамических задач методом Ньюмарка(линейное ускорение в интервале времени)
classdef Newmark < handle
    properties
        b = 0.5    % Параметр демпфирования (0.5 для усреднения) >= 0.5
        a = 0.25   % Параметр устойчивости (0.25 для неявной схемы) >=  0.25 * (0.5 + beta)^2
        % Состояние системы
        coeffs      % Постоянные интегрирования [8x1]
        time_step   % Временной шаг             (Число)
        count = 0
        t = 0       % Текущее время             (Число)
        fixed      % Данные закрепления        (ConstraintData)
        moved
        % Матрицы системы
        M           % Матрица масс              (sparse)
        K           % Матрица жесткости         (sparse)
        K_moved
    end
    methods
        function UVA = IC(this,U0,V0,A0)
            UVA = [U0,V0,A0];
        end

        function setParam(this,dt,a,b)
            if nargin == 2
                a = this.a;
                b = this.b;
            end
            this.time_step = dt;
            this.coeffs = [1/a/dt^2; ...
                             b/a/dt; ...
                             1/a/dt; ...
                          0.5/a - 1; ...
                            b/a - 1; ...
               0.5 * dt * (b/a - 2); ...
                       dt * (1 - b); ...
                              b*dt];
            this.a = a;
            this.b = b;
        end

        function assemble(this, element, geometry)
            [this.K,this.M] = element.assemble(geometry);
        end

        function constrain(this, fixed, moved)
            this.fixed = fixed;
            this.moved = moved;
            toZero = [fixed;moved];

            this.K_moved = this.K(:,moved);

            this.K(toZero,:) = 0;
            # this.K(:,toZero) = 0;
            this.K(:,fixed) = 0;
            this.K(sub2ind(size(this.K),toZero,toZero)) = 1;

            this.M(toZero,:) = 0;
            this.M(:,fixed) = 0;
            # this.K(:,toZero) = 0;

            # this.M(:,toZero) = 0;
            # this.M(sub2ind(size(this.M),toZero,toZero)) = 1;

            # this.K = chol(this.K + this.coeffs(1) * this.M);
            this.K = this.K + this.coeffs(1) * this.M;
        end

        function nextUVA = step(this, UVA, force)
            U_prev = UVA(:,1);
            V_prev = UVA(:,2);
            A_prev = UVA(:,3);

            q_eff = force + this.M * (this.coeffs(1) * U_prev + this.coeffs(3) * V_prev + this.coeffs(4) * A_prev);
            # q_eff -= sum(this.K_moved * force(this.moved),2);
            # q_eff(this.moved) = force(this.moved);
            q_eff(this.fixed) = 0;

            U = this.K\q_eff;

            A = this.coeffs(1) * (U - U_prev) - this.coeffs(3) * V_prev - this.coeffs(4) * A_prev;
            V = V_prev + this.coeffs(7) * A_prev + this.coeffs(8) * A;

            this.count += 1;
            this.t = this.time_step * this.count;

            nextUVA = [U,V,A];
        end
    end
end
