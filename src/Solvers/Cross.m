% Решатель динамических задач методом центральных разностей(Явный)
classdef Cross < handle
    properties
        % Сборщик глобальных матриц
        assembler
        % Состояние системы
        dofIndices  % Закреплённые степени свободы
        dofValues   % Заданные перемещения, обычно нулевые
        dt          % Временной шаг             (Число)
        % Матрицы системы
        M           % Матрица масс              (sparse)
        % Результат счёта
        U           % Узловые перемещения       [Nx1]
        V           % Узловые скорости          [Nx1]
        A           % Узловые ускорения         [Nx1]
    end
    methods
        function obj = Cross(dt, assembler)
            obj.dt = dt;
            obj.assembler = assembler;
            M_full = assembler.mass();
            diag_M = sum(M_full,2); % Lumped Mass 
            obj.M = spdiags(diag_M, 0, size(M_full,1), size(M_full,2));
        end

        function applyBC(obj, dofIndices, dofValues)
            obj.dofIndices = dofIndices(:);

            if nargin < 3 || isempty(dofValues)
                obj.dofValues = zeros(numel(dofIndices), 1);
            else
                obj.dofValues = dofValues(:);
            end
        end

        function applyIC(obj, U0, V0, F0)
            U0 = U0(:);
            V0 = V0(:);
            F0 = F0(:);
            
            U0(obj.dofIndices) = obj.dofValues;
            V0(obj.dofIndices) = 0;

            stress_IP = obj.assembler.integrationPointStress(reshape(U0,obj.assembler.problem.dofPerNode,[]));
            F_int = obj.assembler.internalForce(stress_IP);

            F_int = F_int(:);
            A0 = obj.M \ (F0(:) - F_int);

            A0(obj.dofIndices) = 0;

            obj.U = U0;
            obj.V = V0;
            obj.A = A0;

            %Первый шаг
            obj.V = obj.V + 0.5 * obj.dt * obj.A;
            obj.U = obj.U + obj.dt * obj.V;
        end

        function step(obj,force)
            stress_IP = obj.assembler.integrationPointStress(reshape(obj.U,obj.assembler.problem.dofPerNode,[]));
            F_int = obj.assembler.internalForce(stress_IP);

            F = force(:) - F_int(:); % Эффективная правая часть

            obj.A = obj.M\F;

            obj.V = obj.V + obj.dt * obj.A;
            obj.U = obj.U + obj.dt * obj.V;

            obj.U(obj.dofIndices) = obj.dofValues;
            obj.V(obj.dofIndices) = 0;
            obj.A(obj.dofIndices) = 0;
        end
    end
end
