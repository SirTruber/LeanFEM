classdef HM24 < Module
    properties (Constant)
        INPUT_DATA = {}
        OUTPUT_DATA = {'K', 'M'}
    end
    properties
        elasticity,
        density,
        viscosity,
        param
    end
    methods
        function obj = HM24(material)
            tmp = 1/600;
            density = material.density * (tmp(ones(24,24)) + diag(tmp(ones(1,24))));
            viscosity = material.viscosity;
            elasticity = zeros(18, 18);
            elasticity(1:3,1:3) = material.firstLame * ones(3);
            elasticity(1:3,1:3) += 2 * material.secondLame * diag(ones(1,3),3,3);
            elasticity(4:end,4:end) = diag(material.secondLame * ones(15,1));
            param = 1.0;
        end

        function execute(obj,context)
            grid = context.grid;
            n = rows(grid.hexas);
            m = 3 * rows(grid.nodes);
            ij_trip = repelem(3*grid.hexas.'(:),3) + repmat(int32(-2:0),1,n*8)';
            i_trip = repelem(reshape(ij_trip,24,[]),1,24)(:);
            j_trip = repelem(ij_trip,24);
            if ismember('M', active_output)
                [stiffness,mass] = arrayfun(@(i) obj.compute(i, grid),1:n,'UniformOutput',false);
                stiffness = cell2mat(stiffness);
                context.results('K') = sparse(i_trip,j_trip,stiffness.'(:),m,m);
                mass = cell2mat(mass);
                context.results('M') = sparse(ij_trip,ij_trip,mass(:),m,m);
            else
                stiffness = arrayfun(@(i) obj.compute(i, grid.points(i)),1:n,'UniformOutput',false);
                stiffness = cell2mat(stiffness);
                context.results('K') = sparse(i_trip,j_trip,stiffness.'(:),m,m);
            end
%             switch nargout
%                 case 1
%                     stiffness = arrayfun(@(i) obj.compute(i, grid.points(i)),1:n,'UniformOutput',false);
%                     stiffness = cell2mat(stiffness);
%                     K = sparse(i_trip,j_trip,stiffness.'(:),m,m);
%                 case 2
%                     [stiffness,mass] = arrayfun(@(i) obj.compute(i, grid),1:n,'UniformOutput',false);
%                     stiffness = cell2mat(stiffness);
%                     mass = cell2mat(mass);
%                     K = sparse(i_trip,j_trip,stiffness.'(:),m,m);
%                     M = sparse(ij_trip,ij_trip,mass(:),m,m);
%                 case 3
%                     [stiffness,mass,damping] = arrayfun(@(i) obj.compute(i, grid),1:n,'UniformOutput',false);
%                     stiffness = cell2mat(stiffness);
%                     mass = cell2mat(mass);
%                     damping = cell2mat(damping)
%                     K = sparse(i_trip,j_trip,stiffness.'(:),m,m);
%                     M = sparse(ij_trip,ij_trip,mass(:),m,m);
%                     D = sparse(ij_trip,ij_trip,damping(:),m,m);
        end
        function [K,M,D] = compute(obj,points)
            if nargout == 0
                return
            end
            tetraedron = [1 3 6 8; 1 2 6 3; 1 3 8 4; 1 6 5 8; 3 6 8 7];
            determinant = arrayfun(@(i) det([points(tetraedron(i,:),:) ones(4,1)]), 1:rows(tetraedron));
            volume = 1/6 * sum(determinant);

            B = obj.grad(points);

            K = B' * obj.elasticity * B * volume;
            if isargout(2)
                M = volume * obj.density;
            end

            if isargout(3)
                D = -obj.viscosity * K;
            end
        end

        function B = grad(obj,points)
            edges = [1 2; 2 3; 3 4; 4 1; 5 6; 6 7; 7 8; 8 5; 1 5; 2 6; 3 7; 4 8];

            edges = points(edges(:,2),:) - points(edges(:,1),:);
            len = sqrt(sum(edges.^2,2));

            h = obj.param * min(nonzeros(len));

            imaginary = [ h  h  h  0;
                          h  0  0  h;
                          0  0  h  0;
                          0  h  0  h;
                          0  0  h  h;
                          0  h  0  0;
                          h  h  h  h;
                          h  0  0  0];
            V = [ones(8,1) points imaginary];
            d = inv(V);
            B = zeros(18, 24);

            B(1,1:3:24) = d(2,:); %εxx
            B(2,2:3:24) = d(3,:); %εyy
            B(3,3:3:24) = d(4,:); %εzz

            B(4,1:3:24) = d(3,:); %γxy
            B(4,2:3:24) = d(2,:); %γyx

            B(5,2:3:24) = d(4,:); %γyz
            B(5,3:3:24) = d(3,:); %γzy

            B(6,1:3:24) = d(4,:); %γxz
            B(6,3:3:24) = d(2,:); %γzx

            for k = 1:8
                B(7:18,3*k-2:3*k) = [diag(d(5,k)*ones(1,3)); diag(d(6,k)*ones(1,3));diag(d(7,k)*ones(1,3));diag(d(8,k)*ones(1,3))];
            end
        end
%         function K = attach(obj,at_list,K)
%             K(at_list,:) = 0;
%             K(:,at_list) = 0;
%             K(sub2ind(size(K),at_list,at_list)) = 1;
%         end
        function sigma = stressInt(obj,points,delta)
            S = obj.elasticity * obj.grad(points) * delta;
            sigma = 1/sqrt(2) * sqrt((S(1) - S(2))^2 + (S(2) - S(3))^2 + (S(3) - S(1))^2 + 6*(S(4)^2 + S(5)^2 + S(6)^2));
        end
    end
end
