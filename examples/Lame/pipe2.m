function pipe2()
% LAME_CYLINDER Решение задачи Ламе для толстостенного цилиндра
%                в осесимметричной постановке.
% Используются элементы CAX4 (билинейные) и CAX4M (моментная схема).

run('../../src/setup.m'); % Добавить пути к исходникам

% --- Параметры геометрии и нагрузки ---
rInner = 1.0;     % внутренний радиус
rOuter = 5.0;     % внешний радиус
L      = 1.0;     % длина цилиндра (высота в осевом направлении)
pInner = 100e-5;  % внутреннее давление (100 МПа)
pOuter = 0.0;     % внешнее давление

% Параметры сетки
nR = 20;          % число элементов по радиусу
nZ = 5;           % число элементов по высоте

% --- Материал (сталь) ---
steel = Steel();

% --- Генерация осесимметричной сетки ---
grid = createAxisymmetricGrid(rInner, rOuter, L, nR, nZ);

% --- Граничные условия (плоская деформация: u_z = 0 на торцах) ---
bc = boundaryConditionsAxisymmetric(grid);

% --- Внешние силы (давление на внутреннюю и внешнюю поверхности) ---
force = pressureLoadAxisymmetric(grid, rInner, rOuter, pInner, pOuter);

% --- Решение с элементом CAX4 ---
fprintf('Решение с CAX4...\n');
fe_standard = CAX4(steel);
[U_std, stress_std] = solveAxisymmetric(grid, bc, force, fe_standard);

% --- Решение с моментной схемой CAX4M ---
fprintf('Решение с CAX4M...\n');
fe_moment = CAX4M(steel);
[U_mom, stress_mom] = solveAxisymmetric(grid, bc, force, fe_moment);

% --- Аналитическое решение для сравнения ---
% Берём линию узлов вдоль радиуса на середине высоты
z_mid = L/2;
tol = 1e-6;
midNodes = find(abs(grid.nodes(2,:) - z_mid) < tol);
% Сортируем по возрастанию r
[~, idx] = sort(grid.nodes(1, midNodes));
midNodes = midNodes(idx);
r_vals = grid.nodes(1, midNodes);

% Аналитические напряжения (радиальное и окружное)
[sigma_r_an, sigma_theta_an, u_r_an] = lame_analytical(r_vals, rInner, rOuter, ...
    pInner, pOuter, steel.youngModule, steel.poissonRatio);

% Извлекаем численные результаты вдоль выбранной линии
sigma_r_std   = stress_std(1, midNodes);   % σ_rr
sigma_theta_std = stress_std(3, midNodes); % σ_θθ
sigma_r_mom   = stress_mom(1, midNodes);
sigma_theta_mom = stress_mom(3, midNodes);

u_r_std = U_std(1, midNodes);   % перемещения по r
u_r_mom = U_mom(1, midNodes);

% --- Построение графиков ---
figure('Name', 'Напряжения: CAX4 vs CAX4M vs Аналитика');
subplot(2,2,1);
plot(r_vals, sigma_r_an, 'k-', 'LineWidth', 2); hold on;
plot(r_vals, sigma_r_std, 'ro--', 'MarkerSize', 4);
plot(r_vals, sigma_r_mom, 'bs--', 'MarkerSize', 4);
xlabel('Радиус r'); ylabel('\sigma_{rr} (МПа)');
legend('Аналит.', 'CAX4', 'CAX4M', 'Location', 'best');
title('Радиальное напряжение');

subplot(2,2,2);
plot(r_vals, sigma_theta_an, 'k-', 'LineWidth', 2); hold on;
plot(r_vals, sigma_theta_std, 'ro--', 'MarkerSize', 4);
plot(r_vals, sigma_theta_mom, 'bs--', 'MarkerSize', 4);
xlabel('Радиус r'); ylabel('\sigma_{\theta\theta} (МПа)');
legend('Аналит.', 'CAX4', 'CAX4M', 'Location', 'best');
title('Окружное напряжение');

subplot(2,2,3);
plot(r_vals, u_r_an, 'k-', 'LineWidth', 2); hold on;
plot(r_vals, u_r_std, 'ro--', 'MarkerSize', 4);
plot(r_vals, u_r_mom, 'bs--', 'MarkerSize', 4);
xlabel('Радиус r'); ylabel('u_r (см)');
legend('Аналит.', 'CAX4', 'CAX4M', 'Location', 'best');
title('Радиальное перемещение');

% Визуализация эквивалентных напряжений на сетке
subplot(2,2,4);
vis = Visualizer(grid);
vis.showField(fe_standard.vonMises(stress_std));
title('Эквивалентные напряжения по Мизесу (CAX4)');
colorbar;

end

% -------------------------------------------------------------------------
% Генерация сетки в координатах (r, z)
% -------------------------------------------------------------------------
function grid = createAxisymmetricGrid(rInner, rOuter, L, nR, nZ)
    % Количество узлов по направлениям
    numNodesR = nR + 1;
    numNodesZ = nZ + 1;
    numNodes = numNodesR * numNodesZ;
    numElements = nR * nZ;

    % Векторы координат
    rVec = linspace(rInner, rOuter, numNodesR);
    zVec = linspace(0, L, numNodesZ);

    % Создание узлов (3xN, третья координата = 0)
    nodes = zeros(3, numNodes);
    nodeIdx = 0;
    for iz = 1:numNodesZ
        z = zVec(iz);
        for ir = 1:numNodesR
            r = rVec(ir);
            nodeIdx = nodeIdx + 1;
            nodes(:, nodeIdx) = [r; z; 0];
        end
    end

    % Функция для получения индекса узла по (ir, iz)
    nodeAt = @(ir, iz) (iz - 1) * numNodesR + ir;

    % Создание четырёхугольных элементов
    quads = zeros(4, numElements, 'int32');
    elemIdx = 0;
    for iz = 1:nZ
        for ir = 1:nR
            n1 = nodeAt(ir,   iz);
            n2 = nodeAt(ir+1, iz);
            n3 = nodeAt(ir+1, iz+1);
            n4 = nodeAt(ir,   iz+1);
            elemIdx = elemIdx + 1;
            quads(:, elemIdx) = [n1; n2; n3; n4];
        end
    end

    grid = Grid2D();
    grid.name = sprintf('Lame_cylinder_r%g-%g_L%g', rInner, rOuter, L);
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
% -------------------------------------------------------------------------
% Граничные условия (плоская деформация: u_z = 0 на z=0 и z=L)
% -------------------------------------------------------------------------
function bc = boundaryConditionsAxisymmetric(grid)
    tol = 1e-8;
    % Узлы на нижней и верхней границах
    bottomZ = abs(grid.nodes(2,:)) < tol;
    topZ    = abs(grid.nodes(2,:) - max(grid.nodes(2,:))) < tol;
    
    % Закрепляем осевые перемещения (степени свободы с номерами 2, 4, 6, ...)
    bc = [find(bottomZ)*2, find(topZ)*2];
    
    % Если внутренний радиус равен нулю, закрепляем u_r на оси r=0
    if min(grid.nodes(1,:)) < tol
        onAxis = abs(grid.nodes(1,:)) < tol;
        bc = [bc, find(onAxis)*2 - 1];   % степени свободы u_r (нечётные)
    end
end

% -------------------------------------------------------------------------
% Нагрузка от давления на внутреннюю и внешнюю цилиндрические поверхности
% -------------------------------------------------------------------------
function force = pressureLoadAxisymmetric(grid, rInner, rOuter, pInner, pOuter)
    tol = 1e-6;
    force = zeros(size(grid.nodes));   % 3xN_nodes, третья компонента не используется
    
    % Внутренняя поверхность (r = rInner)
    innerNodes = find(abs(grid.nodes(1,:) - rInner) < tol);
    for i = 1:length(innerNodes)
        n = innerNodes(i);
        r = grid.nodes(1, n);
        z = grid.nodes(2, n);
        
        % Находим соседние узлы для вычисления длины дуги в плоскости r-z
        % Для регулярной сетки можно оценить вклад от прилегающих элементов
        % Упрощённо: сила = давление * площадь, отнесённая к узлу
        % Площадь цилиндрической поверхности, приходящаяся на узел:
        %   dA = 2*pi*r * dz, где dz - размер элемента по высоте в окрестности узла
        % Определим dz как расстояние до соседа по z (если есть)
        dz = 0;
        neighbors = [n-1, n+1];
        for nb = neighbors
            if nb > 0 && nb <= size(grid.nodes,2) && abs(grid.nodes(2,nb) - z) > tol
                dz = dz + abs(grid.nodes(2,nb) - z);
            end
        end
        if dz == 0
            % крайний случай (узел на углу) – берём половину расстояния до единственного соседа
            if n > 1, dz = abs(grid.nodes(2,n-1) - z); end
        end
        dA = 2 * pi * r * dz;
        % Радиальная сила (положительное давление pInner создаёт силу +r)
        force(1, n) = force(1, n) + pInner * dA;
    end
    
    % Внешняя поверхность (r = rOuter)
    outerNodes = find(abs(grid.nodes(1,:) - rOuter) < tol);
    for i = 1:length(outerNodes)
        n = outerNodes(i);
        r = grid.nodes(1, n);
        z = grid.nodes(2, n);
        dz = 0;
        neighbors = [n-1, n+1];
        for nb = neighbors
            if nb > 0 && nb <= size(grid.nodes,2) && abs(grid.nodes(2,nb) - z) > tol
                dz = dz + abs(grid.nodes(2,nb) - z);
            end
        end
        if dz == 0 && n > 1
            dz = abs(grid.nodes(2,n-1) - z);
        end
        dA = 2 * pi * r * dz;
        % Внешнее давление действует внутрь (противоположно +r)
        force(1, n) = force(1, n) - pOuter * dA;
    end
    
    % Приводим к вектору-столбцу для решателя
    force = force(1:2, :);   % только u_r и u_z
end

% -------------------------------------------------------------------------
% Решение осесимметричной задачи
% -------------------------------------------------------------------------
function [U, stress] = solveAxisymmetric(grid, bc, force, fe)
    % Сборка глобальной матрицы жёсткости
    K = assemble(fe, grid);
    
    % Статический решатель
    solver = Static(bc, K);
    solver.step(force);
    
    % Перемещения
    U = solver.U;
    U = reshape(U, 2, []);   % 2 x N_nodes: первая строка u_r, вторая u_z
    
    % Напряжения
    [~, stress] = fe.evaluateStrainAndStress(grid, U);
    % stress: 4 строки (σ_rr, σ_zz, σ_θθ, τ_rz)
end

% -------------------------------------------------------------------------
% Аналитическое решение задачи Ламе для плоской деформации
% -------------------------------------------------------------------------
function [sigma_r, sigma_theta, u_r] = lame_analytical(r, a, b, p_i, p_o, E, nu)
    % r - массив радиальных координат
    % a, b - внутренний и внешний радиусы
    % p_i, p_o - внутреннее и внешнее давление
    % E, nu - модуль Юнга и коэффициент Пуассона
    
    % Константы
    C1 = (p_i * a^2 - p_o * b^2) / (b^2 - a^2);
    C2 = (p_i - p_o) * a^2 * b^2 / (b^2 - a^2);
    
    sigma_r = C1 - C2 ./ r.^2;
    sigma_theta = C1 + C2 ./ r.^2;
    
    % Перемещение (плоская деформация)
    % u_r = 1/(2*mu) * ( (1-2*nu)*C1*r + C2/r )
    mu = E / (2*(1+nu));
    u_r = 1/(2*mu) * ( (1-2*nu)*C1.*r + C2./r );
end