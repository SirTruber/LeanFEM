function disk
% Осесимметричная задача
% Диск, закреплённый по внешнему контуру,
% на верхнюю поверхность действует равномерное давление.
run('../../src/setup.m');

R = 14.85;        % внешний радиус, см
t = 1.5;          % толщина, см
pressure = 1.7e-5;% давление, 1.7 МПа
nr = 30;          % число элементов по радиусу
nz = 10;          % число элементов по толщине

% Материал (сталь)
mat = Steel();

% Осесимметричная задача, билинейный элемент
problem = AxisymmetricElasticity(C2D4M(), mat);

grid = makeGrid(nr,nz,R,t);

% Сборка глобальной матрицы жёсткости
K = assemble(problem, grid);

[bcDofs,bcVals] = Boundary(grid,R);

F = force(grid,pressure);

solver = Static(K);
solver.applyBC(bcDofs, bcVals);
solver.step(F);
U = solver.U;

U_vis = reshape(U,2,[]);
U_vis = [U_vis;zeros(1,size(U_vis,2))];
vis = Visualizer(grid);
# F_vis = reshape(F,2,[]);
# F_vis = [F_vis;zeros(1,size(F_vis,2))];
# vis.showForce(F_vis,-1000);
vis.showDisplacements(U_vis, 1);
[~,stress] = problem.evaluateStrainAndStress(grid,reshape(U,2,[]));
stress = stress * 1e5;
vis.showField(stress(1,:));
end

function [bcDofs,bcVals] = Boundary(grid,R)
    % Граничные условия
    % 1. Ось симметрии r = 0: u_r = 0 (закрепляем X-степень свободы)
    % 2. Внешний контур r = R: u_r = 0 и u_z = 0 (закрепляем оба перемещения)
    axis_nodes = find(abs(grid.nodes(1,:)) < 1e-10);          % r == 0
    outer_nodes = find(abs(grid.nodes(1,:) - R) < 1e-10);     % r == R

    dofs_axis_u = 2*axis_nodes - 1;        % X-компонента (r) для оси
    dofs_outer_u = 2*outer_nodes - 1;      % X-компонента для внешней границы
    dofs_outer_v = 2*outer_nodes;          % Y-компонента (z) для внешней границы

    bcDofs = unique([dofs_axis_u, dofs_outer_u, dofs_outer_v]);
    bcVals = zeros(size(bcDofs));

end

function F = force(grid,pressure)

    F = zeros(2 * grid.numNodes(), 1);

    for e = 1:grid.numElements()
        elem_nodes = grid.quads(:, e);
        coords = grid.nodes(:, elem_nodes);              % [2 x 4]
        % Ищем грань, принадлежащую нижней поверхности (два узла с z = 0)
        top_mask = abs(coords(2,:)) < 1e-10;
        if sum(top_mask) ~= 2
            continue;   % элемент не выходит на верхнюю поверхность
        end
        % Локальные номера двух верхних узлов
        idx = find(top_mask);
        A = idx(1);
        B = idx(2);
        rA = coords(1, A);
        rB = coords(1, B);
        dL = abs(rB - rA);
        r_mid = (rA + rB) / 2;
        % Сила давления на всю грань: p * (2π * r_mid * dL)
        F_edge = pressure * 2 * pi * r_mid * dL;

        % Распределяем поровну между двумя узлами
        dof_zA = 2 * elem_nodes(A);   % Z-компонента узла A
        dof_zB = 2 * elem_nodes(B);   % Z-компонента узла B
        F(dof_zA) = F(dof_zA) + F_edge / 2;
        F(dof_zB) = F(dof_zB) + F_edge / 2;
    end
end

function grid = makeGrid(nr,nz,R,t)
    r_nodes = linspace(0, R, nr+1);
    z_nodes = linspace(0, t, nz+1);

    % Создание массива узлов: первая строка – r, вторая – z, третья – 0
    [RR, ZZ] = meshgrid(r_nodes, z_nodes);
    nodes = [RR(:)'; ZZ(:)'; zeros(1, numel(RR))];

    % Нумерация узлов: по столбцам meshgrid (z – строки, r – столбцы)
    % Это соответствует [z, r] индексам.

    % Формирование четырёхугольных элементов
    quads = zeros(4, nr*nz);
    idx = 1;
    for i = 1:nr
        for j = 1:nz
            % Узлы углов элемента: (i,j) – нижний левый в пространстве (r,z)
            n1 = i*(nz+1) + j;              % правый нижний
            n2 = i*(nz+1) + j + 1;          % правый верхний
            n3 = (i-1)*(nz+1) + j + 1;      % левый верхний
            n4 = (i-1)*(nz+1) + j;          % левый нижний
            quads(:, idx) = [n1; n2; n3; n4];
            idx = idx + 1;
        end
    end

    % Создание объекта сетки Grid2D
    grid = Grid2D();
    grid.name = 'disk';
    grid.nodes = nodes;
    grid.quads = quads;
end
