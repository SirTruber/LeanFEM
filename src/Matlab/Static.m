% Решатель линейных статических задач
classdef Static < handle
    properties
        % Состояние системы
        fixed      % Данные закрепления (векторы)
        % Матрицы системы
        K           % Матрица жесткости (sparse)
    end
    methods
%         function obj = Static()
%             obj.fixed = fixed;

%             obj.K = stiffness;

%             toZero = unique([fixed,moved]);
%             obj.K(toZero,:) = 0;
%             obj.K(:,fixed) = 0;
%             obj.K(sub2ind(size(obj.K),toZero,toZero)) = 1;

%             obj.U = zeros(size(obj.K,1),1);
%         end

        function assemble(this, element, geometry)
            this.K = element.assemble(geometry);
        end

        function constrain(this, fixed, moved)
            this.fixed = fixed;
            toZero = [fixed,moved];

            this.K(toZero,:) = 0;
            this.K(:,fixed) = 0;
            this.K(sub2ind(size(this.K),toZero,toZero)) = 1;
        end

        function [U, R] = solve(this,force)
            q = force;
            q(this.fixed) = 0;
            U = this.K \ q;
        end
    end
end
