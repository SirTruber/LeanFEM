classdef Solver
    properties
        finite_element,
        grid
    end
    methods
        function obj = Solver(material, grid)
            obj.finite_element = HM24(material);
            obj.grid = grid;
        end

        function K = stiffness(obj)
            i_trip = [];
            j_trip = [];
            v_trip = [];
            for i=1:size(obj.grid.elem,1)
                obj.finite_element.nodes = obj.grid.points(i);
                obj.finite_element.volume = obj.grid.volume(i);
                obj.finite_element.param = obj.grid.minHight(i);
                tmp = repmat(repelem(3*obj.grid.elem(i,:),3) + repmat(int32(-2:0),1,8),24,1);
                i_trip = [i_trip reshape(tmp,1,[])];
                j_trip = [j_trip reshape(tmp.',1,[])];
                v_trip = [v_trip reshape(obj.finite_element.stiffness(),1,[])];
            end
            K = sparse(i_trip,j_trip,v_trip);
        end

        function q = force(obj)
            n = size(obj.grid.mesh,1);
            q = zeros(3 * n,1);
            for i = 1:n
                if (obj.grid.mesh(i,2) == 1 && (obj.grid.mesh(i,3) >= 4 || obj.grid.mesh(i,3) <= 6))
                q(3*i - 1) = 1/9;
                end
            end
        end

        function [K,q] = attach(obj, K, q)
            n = size(obj.grid.mesh,1);
            for i = 1:n
                if (obj.grid.mesh(i,3) == 0 || obj.grid.mesh(i,3) == 10)
                    left = 3 * i - 3;
                    right = 3 * (n - i);
                    q(left + 1:left+3) = 0;
                    K11 = K(1:left,1:left);
                    K13 = K(1:left,left+4:end);
                    %K31 = K(left + 4:end,1:left);
                    K33 = K(left + 4:end,left + 4:end);
                    K = [K11 zeros(left,3) K13;
                         zeros(3,left) speye(3) zeros(3,right);
                         K13' zeros(right,3) K33];
                end
            end
        end
    end
end
