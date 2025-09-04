classdef HM24 < handle
    properties (Constant)
        NODES_PER_EL = 8;
        DOF_PER_NODE = 3;
        IMAGINARY_DOF = 4;
        STRAIN_COMPONENTS = 18;
    end
    properties
        elasticity  % Матрица упругих постоянных(симметричная, положительно определённая)[18x18]
        density     % Матрица плотности, сумма элементов равна плотности материала [24x24]
        param       % Параметр моментной схемы. Определяет влияние моментных составляющих на решение (число)
    end
    methods
        function this = HM24(material,distributed)
            tmp = eye(24);
            if distributed
                tmp += ones(24);
            end

            this.density = material.density * tmp / sum(tmp(:));
            this.elasticity = blkdiag(material.firstLame(ones(3)) + 2 * material.secondLame * eye(3), material.secondLame * eye(15));
            this.param = 1.0;
        end

        function [K,M] = assemble(this,geometry,elemID)
            if nargin < 3
                elemID = 1:geometry.numCells;
            end
            grid = geometry.mesh;
            hexas = geometry.mesh.hexas(:,elemID);
            numDOF = this.DOF_PER_NODE * (max(hexas(:)) - min(hexas(:)) + 1);
            [~, volume] = grid.volume(elemID);

            ij = 3 * repelem(hexas,3,1) - repmat([2;1;0],8, numel(elemID));
            [i,j] = ndgrid(1:24, 1:24);
            i_glob = ij(i(:),:);
            j_glob = ij(j(:),:);

            grad = arrayfun(@(i) this.computeGradient(grid.points(i)),elemID,'UniformOutput',false);

            stiffness = arrayfun(@(i) this.computeStiffnes(grad{i},volume(i)),elemID,'UniformOutput',false);
            stiffness = cat(3, stiffness{:}); % Объединяем в 3D-массив 24×24×numel(elemID)
            K = sparse(i_glob(:), j_glob(:),stiffness(:),numDOF,numDOF);

            if nargout == 2
                mass = arrayfun(@(i) this.computeMass(volume(i)),elemID,'UniformOutput',false);
                mass = cat(3, mass{:});
                M = sparse(i_glob(:), j_glob(:),mass(:),numDOF,numDOF);
            end
        end

        function K = computeStiffnes(this, B, vol)
            K = B' * this.elasticity * B * vol;
        end

        function M = computeMass(this, vol)
            M = this.density * vol;
        end

        function B = computeGradient(this,points)
            edges = [1 2; 2 3; 3 4; 4 1; 5 6; 6 7; 7 8; 8 5; 1 5; 2 6; 3 7; 4 8];

            edges = points(:,edges(:,2)) - points(:,edges(:,1));
            len = sqrt(sum(edges.^2));

            h = this.param * min(nonzeros(len));

            imaginary = [ h  h  h  0;
                          h  0  0  h;
                          0  0  h  0;
                          0  h  0  h;
                          0  0  h  h;
                          0  h  0  0;
                          h  h  h  h;
                          h  0  0  0];
            V = [ones(this.NODES_PER_EL,1), points', imaginary];
            d = inv(V);
            B = zeros(this.STRAIN_COMPONENTS, this.DOF_PER_NODE*this.NODES_PER_EL);

            B(1,1:3:24) = d(2,:); %εxx
            B(2,2:3:24) = d(3,:); %εyy
            B(3,3:3:24) = d(4,:); %εzz

            B(4,1:3:24) = d(3,:); %γxy
            B(4,2:3:24) = d(2,:); %γyx

            B(5,2:3:24) = d(4,:); %γyz
            B(5,3:3:24) = d(3,:); %γzy

            B(6,1:3:24) = d(4,:); %γxz
            B(6,3:3:24) = d(2,:); %γzx

            B(7:18,:) = repmat(eye(3), this.IMAGINARY_DOF, this.NODES_PER_EL).*repelem(d(5:8,:),this.DOF_PER_NODE,this.DOF_PER_NODE);
        end
    end
end

%!function value = testMaterial
%!  value = struct('density', 7.8e-09, 'young_module', 2100,'poisson_ratio', 0.3);
%!  value.firstLame =  value.poisson_ratio * value.young_module / (1 - value.poisson_ratio * (1 + 2 * value.poisson_ratio));
%!  value.secondLame = 0.5 * value.young_module / (1 + value.poisson_ratio);
%!endfunction
%!
%!function mesh = testMesh()
%!  nodes = [0 1 1 0 0 1 1 0; 0 0 1 1 0 0 1 1;0 0 0 0 1 1 1 1];
%!  hexas = int32([1;2;3;4;5;6;7;8]);
%!  mesh = Mesh(nodes, hexas);
%!endfunction
%!
%!test #Создание элемента
%!
%! mat = testMaterial;
%! el = HM24(mat);
%!
%! assert(size(el.elasticity),[18 18]);
%! assert(issymmetric(el.elasticity));
%!
%! assert(size(el.density),[24 24]);
%! assert(abs(sum(el.density(:)) - mat.density) < 1e-8);
%!
%! assert(el.param == 1.0);
%!
%!test #Вычисление градиентной матрицы
%!
%! mat = testMaterial;
%! el = HM24(mat);
%!
%!test #Вычисление матрицы жёсткости прямоугольного куба
%!
%!test #Вычисление матрицы жёсткости криволинейного куба
%!
%!test #Вычисление матрицы масс куба
%!
%!test #Ассемблирование матриц для нескольких элементов
%!
