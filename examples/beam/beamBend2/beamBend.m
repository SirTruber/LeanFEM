function beamBend
run('../../../src/setup.m'); % Добавить пути к src
grid = loadFrom('brus.4ekm'); % Загрузка сетки из файла

P = 1e-5; % Задание внешнего момента: 1 Н*м
bc = Boundary(grid); % Задание граничных условий
F = ExForce(grid,P); % Задание правой части

% Материал (сталь)
mat = Steel();

% Осесимметричная задача, билинейный элемент
problem = SolidElasticity(C3D8M(), mat);

a = Assembler(problem, grid);

solver = Static(a);
solver.applyBC(bc);
solver.step(F);
U = solver.U;

[~,stress] = problem.evaluateStrainAndStress(grid,reshape(U,3,[])); % Напряжения однородные. Возмущения только рядом с заделкой

# vM = feP.vonMises(stress); % Вычисление эквивалентных напряжений Мизеса

vis = Visualizer(grid); % Посмотреть сетку
%vis.showForce(force,10000); % Посмотреть силы
%vis.showDisplacements(UP,10); % Посмотреть перемещения
vis.showField(stress(1,:)) % Посмотреть напряжение SYY
%vis.showField(vM) % Посмотреть напряжение VON
end

function bc = Boundary(grid)
    right = find(grid.nodes(1,:)==0); % Номера узлов на правом конце
    bc=[right * 3-2; right * 3-1; right * 3]; % Граничные условия, закрепления по XYZ
end

function force = ExForce(grid,My)
    B = find(grid.nodes(1,:)==10); % Номера узлов на левом конце
    force = zeros(size(grid.nodes));   % Размер вектора внешних сил = количество степеней свободы

    C = (grid.nodes(2,B) == 0 | grid.nodes(2,B) == 1); % Логическое условие, лежит ли узел на грани
    D = (grid.nodes(3,B) == 0 | grid.nodes(3,B) == 1);
    force(1,B) = 10 * My *(grid.nodes(2,B) - 0.5); % F = My/l

    force(1,B(C)) = force(1,B(C))* 0.5; % Узлы на гранях испытывают половину нагрузки,
    force(1,B(D)) = force(1,B(D))* 0.5; % а на углах - только четверть
end

function U = solve(grid,bc,force,fe)
    K = assemble(fe,grid); % Собираем глобальную матрицу жесткости
    solver = Static(bc,K); % Инициализируем решатель
    solver.step(force); % Решаем задачу
    U = solver.U; % Забираем результат расчёта
    U = reshape(U,3,[]); % Возвращаем матрицу [Ux;Uy;Uz]
end
