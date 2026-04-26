function pipe2
run('../../src/setup.m');

% Геометрия и материал
a = 2; b = 10; h = 0.5;
nr = 8;   % число элементов по радиусу
nz = 4;   % число элементов по толщине
p = 1e-4; % 10 МПа
mat = Steel();

grid = makeGrid(nr,nz,a,b,h);

elem = CAX4();

elem.quadrature = GaussQuadrature(2, 3);

problem = AxisymmetricElasticity(elem, mat);

bc = Boundary(grid,a,b,h);

F = exForce(grid,p,a);
asm = Assembler(problem, grid);

solver = Static(asm);
solver.applyBC(bc);
solver.step(F);
U = solver.U;

U_vis = reshape(U,2,[]);
U_vis = [U_vis;zeros(1,size(U_vis,2))];
vis = Visualizer(grid);
xlim([a,b]);
vis.showDisplacements(U_vis);
% Напряжения через Assembler
stress = 1e5 * asm.nodalStress(reshape(U,2,[]));

vis.showField(problem.vonMises(stress));

% Выделим узлы на средней высоте (z = h/2)
mid_nodes = find(abs(grid.nodes(2,:) - h/2) < 1e-8);
r_mid = grid.nodes(1, mid_nodes);
sigma_rr_num = stress(1, mid_nodes);
sigma_tt_num = stress(3, mid_nodes);

% sigma_rr(a) = 0, u_r(b) = 0
coeff = [1, -a^(-2);1/(mat.firstLame + mat.secondLame), 1/(mat.secondLame*b^2)] \ [-p;0];
# A = -p * a^2 / (b^2 - a^2);
# B = -p * a^2 * b^2 / (b^2 - a^2);
sigma_rr_an = 1e5 * (coeff(1) - coeff(2) ./ r_mid.^2);
sigma_tt_an = 1e5 * (coeff(1) + coeff(2) ./ r_mid.^2);
#
# % Визуализация
figure;
plot(r_mid, sigma_rr_an, 'b-', 'LineWidth', 2); hold on;
plot(r_mid, sigma_rr_num, 'bo', 'MarkerSize', 8);
plot(r_mid, sigma_tt_an, 'r-', 'LineWidth', 2);
plot(r_mid, sigma_tt_num, 'rs', 'MarkerSize', 8);
xlabel('r, см'); ylabel('\sigma, МПа');
legend('\sigma_{rr} аналит.', '\sigma_{rr} числ.', ...
       '\sigma_{\theta\theta} аналит.', '\sigma_{\theta\theta} числ.');
title('Верификация осесимметричного элемента CAX4');
end

function grid = makeGrid(nr,nz,a,b,h)
% Сетка: равномерная по r и z
    r_nodes = linspace(a, b, nr+1);
    z_nodes = linspace(0, h, nz+1);

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
    grid.name = 'cylinder';
    grid.nodes = nodes;
    grid.quads = quads;
end

function bc = Boundary(grid,a,b,h)
    eps = 1e-8;
    inner_nodes = find(abs(grid.nodes(1,:) - a) < eps);
    outer_nodes = find(abs(grid.nodes(1,:) - b) < eps);
    top_nodes   = find(abs(grid.nodes(2,:) - h) < eps);
    bottom_nodes = find(abs(grid.nodes(2,:)) < eps);

    % u_r = 0 на внешней поверхности
    dof_outer_u = 2*outer_nodes - 1;
    % u_z = 0 на торцах
    dof_top_v    = 2*top_nodes;
    dof_bottom_v = 2*bottom_nodes;

    bc = unique([dof_outer_u, dof_top_v, dof_bottom_v]);
end

function force = exForce(grid,p,a)

% Нагрузка: давление на внутреннюю поверхность
force = zeros(2*grid.numNodes(), 1);
% Интегрируем давление p по граням элементов на r=a
% В осесимметричном случае сила: F = p * 2*pi*r * L (L - длина грани)
for e = 1:grid.numElements()
    elem_nodes = grid.quads(:, e);
    coords = grid.nodes(1:2, elem_nodes);
    % Ищем грань, лежащую на r=a
    mask = abs(coords(1,:) - a) < 1e-8;
    if sum(mask) ~= 2
        continue;
    end
    idx = find(mask);
    z1 = coords(2, idx(1));
    z2 = coords(2, idx(2));
    L = abs(z2 - z1);
    % Давление создаёт силу в положительном направлении r (к центру)
    f = p * 2*pi * a * L;
    % Распределяем поровну между двумя узлами
    dof_r1 = 2*elem_nodes(idx(1)) - 1;
    dof_r2 = 2*elem_nodes(idx(2)) - 1;
    force(dof_r1) = force(dof_r1) + f/2;
    force(dof_r2) = force(dof_r2) + f/2;
end
end
