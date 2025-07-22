classdef HM24 < handle
    properties
        material
        elasticity  % Матрица упругих постоянных(симметричная, положительно определённая)[18x18]
        density     % Матрица плотности, сумма элементов равна плотности материала [24x24]
        param       % Параметр моментной схемы. Определяет влияние моментных составляющих на решение (число)
    end
    methods
        function obj = HM24(material)
            obj.material = material;
            obj.density = material.density/600 * (ones(24,24) + eye(24)); % 1/600 для нормировки
            obj.elasticity = blkdiag(material.firstLame(ones(3)) + 2 * material.secondLame * eye(3), material.secondLame * eye(15));
            obj.param = 1.0;
        end

        function [K,M] = assemble(obj,grid)
            n = rows(grid.hexas);
            m = 3 * rows(grid.nodes);

            ij = 3 * repelem(grid.hexas,1,3) - repmat([2,1,0],size(grid.hexas,1),8);
            [i,j] = ndgrid(1:24, 1:24);
            i_glob = ij(:,i(:))';
            j_glob = ij(:,j(:))';

            if nargout == 2
                [stiffness,mass] = arrayfun(@(i) obj.compute(grid.points(i)),1:n,'UniformOutput',false);
                stiffness = cat(3, stiffness{:});      % Объединяем в 3D-массив 24×24×n
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

            B = obj.grad(points);
            K = B' * obj.elasticity * B * volume;

            if isargout(2)
                M = volume * obj.material.density * eye(24) / 24;
%                 M = volume * obj.density;
            end
%             if isargout(3)
%                 D = -obj.viscosity * K;
%             end
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

            B(7:18,:) = repmat(eye(3), 4, 8).*repelem(d(5:8,:),3,3);
        end
    end
end
