classdef TL12
    properties
        elasticity
        density,
        viscosity,
    end
    methods
        function obj = TL12(material)
            tmp = 1/156;
            obj.density = material.density * (tmp(ones(12,12)) + diag(tmp(ones(1,12))));
            obj.elasticity = zeros(6,6);
            obj.elasticity(1:3,1:3) = material.firstLame * ones(3);
            obj.elasticity(1:3,1:3) += 2 * material.secondLame * diag(ones(1,3),3,3);
            obj.elasticity(4:end,4:end) = diag(material.secondLame * ones(3,1));
        end
%
%         function [K,M,D] = globalCompute(obj,grid)
%             step = 12 * 12;
%             n = size(grid.elem,1);
%             m = 3* size(grid.mesh,1);
%             i_trip = zeros(step * n,1);
%             j_trip = zeros(step * n,1);
%             k_trip = zeros(step * n,1);
%
%             template = repmat(int32(-2:0),1,4);
%             core = [1 3 6 8];
%             switch nargout
%                 case 1
%                     for i=1:n
%                         stiffness = obj.compute(grid.points(i));
%                         tmp = repmat(repelem(3*grid.elem(i,core),3) + template,12,1);
%                         i_trip((i - 1) * step + 1:i * step,1) = reshape(tmp,1,[]);
%                         j_trip((i - 1) * step + 1:i * step,1) = reshape(tmp.',1,[]);
%                         k_trip((i - 1) * step + 1:i * step,1) = reshape(stiffness,1,[]);
%                     end
%                     K = sparse(i_trip,j_trip,k_trip,m,m);
%                 case 2
%                     ij_trip = zeros(12 * n,1);
%                     m_trip = zeros(12 * n,1);
%                     for i=1:n
%                         [stiffness,mass] = obj.compute(grid.points(i));
%                         tmp = repmat(repelem(3*grid.elem(i,core),3) + template,12,1);
%                         i_trip((i - 1) * step + 1:i * step,1) = reshape(tmp,1,[]);
%                         j_trip((i - 1) * step + 1:i * step,1) = reshape(tmp.',1,[]);
%                         ij_trip((i - 1) * 12 + 1:i * 12,1) = tmp(1,:);
%                         k_trip((i - 1) * step + 1:i * step,1) = reshape(stiffness,1,[]);
%                         m_trip((i - 1) * 12 + 1:i * 12,1) = reshape(mass,1,[]);
%                     end
%                     K = sparse(i_trip,j_trip,k_trip,m,m);
%                     M = sparse(ij_trip,ij_trip,m_trip,m,m);
%                 case 3
%                     ij_trip = zeros(12 * n,1);
%                     m_trip = zeros(12 * n,1);
%                     d_trip = zeros(12 * n,1);
%                     for i=1:n
%                         [stiffness,mass,damping] = obj.compute(grid.points(i));
%                         tmp = repmat(repelem(3*grid.elem(i,core),3) + template,12,1);
%                         i_trip((i - 1) * step + 1:i * step,1) = reshape(tmp,1,[]);
%                         j_trip((i - 1) * step + 1:i * step,1) = reshape(tmp.',1,[]);
%                         ij_trip((i - 1) * 12 + 1:i * 12,1) = tmp(1,:);
%                         k_trip((i - 1) * step + 1:i * step,1) = reshape(stiffness,1,[]);
%                         m_trip((i - 1) * 12 + 1:i * 12,1) = reshape(mass,1,[]);
%                         d_trip((i - 1) * 12 + 1:i * 12,1) = reshape(damping,1,[]);
%                     end
%                     K = sparse(i_trip,j_trip,k_trip,m,m);
%                     M = sparse(ij_trip,ij_trip,m_trip,m,m);
%                     D = sparse(ij_trip,ij_trip,d_trip,m,m);
%                 end
%             end
        function [K,M,D] = compute(obj,nodes)
            if nargout == 0
                return
            end
            n = [ones(8,1) nodes];
            volume = -1/6 * (det(n([1 3 6 8],:)) + det(n([1 2 6 3],:)) + det(n([1 3 8 4],:)) + det(n([1 6 5 8],:)) + det(n([3 6 8 7],:)));

            B = obj.grad(nodes([1 3 6 8],:));
            K = B' * obj.elasticity * B * volume;

            if nargout > 1
                M = 1/4 * volume * ones(12,1) * obj.material.density; %maybe try 1/size(unique(nodes,2),2) for unique vertices
            end

            if nargout > 2
                D = 1/4 * volume * ones(12,1) * obj.material.viscosity;
            end
        end

        function B = grad(obj,nodes)

            V = [ones(4,1) nodes];
            d = inv(V);
            B = zeros(6, 12);

            B(1,1:3:12) = d(2,:);
            B(2,2:3:12) = d(3,:);
            B(3,3:3:12) = d(4,:);

            B(4,1:3:12) = d(3,:);
            B(4,2:3:12) = d(2,:);

            B(5,2:3:12) = d(4,:);
            B(5,3:3:12) = d(3,:);

            B(6,1:3:12) = d(4,:);
            B(6,3:3:12) = d(2,:);
        end
%         function K = attach(obj,at_list,K)
%             left = at_list - 1;
%             right = size(K,1) - at_list;
%             for i = 1:length(at_list)
%                 K11 = K(1:left(i),1:left(i));
%                 K13 = K(1:left(i),left(i)+2:end);
%                 K33 = K(left(i)+2:end,left(i)+2:end);
%                 K = [K11 zeros(left(i),1) K13;
%                      zeros(1,left(i)) speye(1) zeros(1,right(i));
%                      K13' zeros(right(i),1) K33];
%             end
%         end
        function sigma = stressInt(obj,nodes,u)
            S = obj.elasticity * obj.grad(nodes([1 3 6 8],:)) * u([1 2 3 7 8 9 16 17 18 22 23 24]);
            sigma = 1/sqrt(2) * sqrt((S(1) - S(2))^2 + (S(2) - S(3))^2 + (S(3) - S(1))^2 + 6*(S(4)^2 + S(5)^2 + S(6)^2));
        end
    end
end
