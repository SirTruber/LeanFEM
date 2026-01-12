function beamStretch
run('../../../src/setup.m'); % Добавить пути к src
grid = loadFrom('brus.4ekm'); % Загрузка сетки из файла
P = 1e-3; % Задание внешнего давления: 100 МПа
bc = Boundary(grid); % Задание граничных условий
force = ExForce(grid,P); % Задание правой части

steel = Steel(); % Тип материала
%steel = Material('steel',7.8,2.1,0.4999); % Практически несжимаемый материал

feP = C3D8(steel,2); % Тип конечного элемента - полилинейный
feM = C3D8M(steel); % Тип конечного элемента - моментный

UP = solve(grid,bc,force,feP); 
UM = solve(grid,bc,force,feM);

volumetricLocking(grid,UM,UP,steel,P);
alongX(grid,UM,UP,steel,P);

[~,stress] = feP.evaluateStrainAndStress(grid,UP); % Напряжения однородные. Возмущения только рядом с заделкой
%vM = feP.vonMises(stress); % Вычисление эквивалентных напряжений Мизеса

%vis = Visualizer(grid); % Посмотреть сетку
%vis.showForce(force,100); % Посмотреть силы
%vis.showDisplacements(UP,100); % Посмотреть перемещения
%vis.showField(stress(1,:)) % Посмотреть напряжение SXX
%vis.showField(vM) % Посмотреть напряжение VON
end

function bc = Boundary(grid)
    right = find(grid.nodes(1,:)==0); % Номера узлов на правом конце
    bc=[right * 3-2; right * 3-1; right * 3]; % Граничные условия, закрепления по XYZ
end

function force = ExForce(grid,P)

    B = find(grid.nodes(1,:)==10); % Номера узлов на левом конце
    
    C = (grid.nodes(2,B) == 0 | grid.nodes(2,B) == 1); % Логическое условие, лежит ли узел на грани
    D = (grid.nodes(3,B) == 0 | grid.nodes(3,B) == 1);

    force = zeros(size(grid.nodes));   % Размер вектора внешних сил = количество степеней свободы

    force(1,B) = 0.25 * 0.25 * P; % F = S*P, используем равномерность сетки

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

function volumetricLocking(grid,UH,UP,material,P)
    E = material.youngModule;
    nu = material.poissonRatio;

    nodes = 15:41:200; % Узлы вдоль оси 0Y
    X = grid.nodes(2,15:41:200) - 0.5; % y-координата узлов, выровненных по центру
    Y = -nu*P/E * X; % Аналитическое решение для одноостного растяжения, эффект Пуассона
    UH = UH(2,nodes); % Численные решения, полученные для различных типов элементов
    UP = UP(2,nodes);

    figure
    plot(X,[Y(:),UH(:),UP(:)],'LineWidth',2);  
    xlabel('y, см');
    ylabel('u_y, см');
    title(['Решение при \nu=',num2str(nu)]);
    legend("Аналитическое","Численное, моментный","Численное, полилинейный");
end

function alongX(grid,UH,UP,material,P)
    E = material.youngModule; % Параметры материала
    nu = material.poissonRatio;

    nodes = 493:533; % Узлы вдоль оси 0X
    X = grid.nodes(1,nodes); % x-координата узлов
    Y = P/E*X; % Аналитическое решение для одноостного растяжения
    UH = UH(1,nodes); % Численные решения, полученные для различных типов элементов
    UP = UP(1,nodes);

    figure
    plot(X,[Y(:),UH(:),UP(:)],'LineWidth',2);
    xlabel('x, см');
    ylabel('u_x, см');
    title(['Решение при \nu=',num2str(nu)]);
    legend("Аналитическое","Численное, моментный","Численное, полилинейный");
end