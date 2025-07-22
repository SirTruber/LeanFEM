classdef TL12
    properties
        material
        elasticity  % Матрица упругих постоянных(симметричная, положительно определённая)[6x6]
        density     % Матрица плотности, сумма элементов равна плотности материала [12x12]
    end
    methods
        function obj = TL12(material)
            obj.material = material;
            obj.density = material.density/156 * (ones(12,12) + eye(12)); % 1/156 для нормировки
            obj.elasticity = blkdiag(material.firstLame(ones(3)) + 2 * material.secondLame * eye(3), material.secondLame * eye(3));
        end

        function [K,M] = assemble(obj,grid)
            n = rows(grid.hexas);
            m = 3 * rows(grid.nodes);

            ij = 3 * repelem(grid.hexas(:,[1 3 6 8]),1,3) - repmat([2,1,0],size(grid.hexas,1),4);
            [i,j] = ndgrid(1:12, 1:12);
            i_glob = ij(:,i(:))';
            j_glob = ij(:,j(:))';

            if nargout == 2
                [stiffness,mass] = arrayfun(@(i) obj.compute(grid.points(i)),1:n,'UniformOutput',false);
                stiffness = cat(3, stiffness{:});      % Объединяем в 3D-массив 12×12×n
                mass = cat(3, mass{:});
                K = sparse(i_glob(:), j_glob(:),stiffness(:),m,m);
                M = sparse(i_glob(:), j_glob(:),mass(:),m,m);
            else
                stiffness = arrayfun(@(i) obj.compute(grid.points(i)),1:n,'UniformOutput',false);
                stiffness = cat(3, stiffness{:});
                K = sparse(i_glob(:), j_glob(:),stiffness(:),m,m);
            end
        end

        function [K,M] = compute(obj,points)
            tetraedron = [1 3 6 8; 1 2 6 3; 1 3 8 4; 1 6 5 8; 3 6 8 7];
            determinant = arrayfun(@(i) det([points(tetraedron(i,:),:) ones(4,1)]), 1:rows(tetraedron));
            volume = 1/6 * sum(determinant);

            B = obj.grad(points([1 3 6 8],:));
            K = B' * obj.elasticity * B * volume;

            if isargout(2)
                M = volume * obj.material.density * eye(12) / 12;
%                 M = volume * obj.density;
            end

%             if nargout > 2
%                 D = 1/4 * volume * ones(12,1) * obj.material.viscosity;
%             end
        end

        function B = grad(obj,points)
            V = [ones(4,1) points];
            d = inv(V);
            B = zeros(6, 12);

            B(1,1:3:12) = d(2,:); %εxx
            B(2,2:3:12) = d(3,:); %εyy
            B(3,3:3:12) = d(4,:); %εzz

            B(4,1:3:12) = d(3,:); %γxy
            B(4,2:3:12) = d(2,:); %γyx

            B(5,2:3:12) = d(4,:); %γyz
            B(5,3:3:12) = d(3,:); %γzy

            B(6,1:3:12) = d(4,:); %γxz
            B(6,3:3:12) = d(2,:); %γzx
        end
    end
end
