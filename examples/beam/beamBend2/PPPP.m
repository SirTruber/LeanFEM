function PPPP
run('../../../src/setup.m'); % Добавить пути к src

figure
lw = 2;
incompress = Material('incompress',7.8,2.1,0.49); % \rho = 7.8 г/см^3, E = 210 ГПа, \nu = 0.49
grid = loadFrom('setk_rude.4ekm'); % Загрузка сетки из файла
alongX = find(grid.nodes(2,:) == 0.5 & grid.nodes(3,:) == 0.5);
[x,order] = sort(grid.nodes(1,alongX));

P = 1e-5;
right = find(grid.nodes(1,:)==0); % Номера узлов на правом конце
force = ExForce(grid,P);
vis = Visualizer(grid); % Посмотреть сетку
# vis.showForce(force,-1e6); % Посмотреть силы
# vis.showAttach(right);
# U = solve(grid, Steel(), C3D8());
#
# hold on
# plot(x,U(2,alongX(order)),'--','LineWidth',lw,'Color','b');
# hold off
#
# U = solve(grid, Steel(), C3D8M());
#
# hold on
# plot(x,U(2,alongX(order)),'--','LineWidth',lw,'Color','r');
# hold off
#
# grid = loadFrom('setk_acc.4ekm'); % Загрузка сетки из файла
# alongX = find(grid.nodes(2,:) == 0.5 & grid.nodes(3,:) == 0.5);
# [x,order] = sort(grid.nodes(1,alongX));
#
# U = solve(grid, Steel(), C3D8());
#
# hold on
# plot(x,U(2,alongX(order)),'-','LineWidth',lw,'Color','b');
# hold off
#
# U = solve(grid, Steel(), C3D8M());
#
# hold on
# plot(x,U(2,alongX(order)),'-','LineWidth',lw,'Color','r');
# hold off
#
# ylim([-0.08,0])
# leg = legend('Полилинейный, редкая сетка','Моментный, редкая сетка','Полилинейный, густая сетка','Моментный, густая сетка')
# title('Steel');
# set(leg, 'FontName', 'Times New Roman', 'FontSize', 14);
# xlabel('Координата вдоль оси бруса, см', 'FontName', 'Times New Roman', 'FontSize', 14,'FontWeight', 'bold', 'FontAngle', 'italic');
# ylabel('Прогиб, см', 'FontName', 'Times New Roman', 'FontSize', 14,'FontWeight', 'bold', 'FontAngle', 'italic');
# figure
# grid = loadFrom('setk_rude.4ekm'); % Загрузка сетки из файла
# alongX = find(grid.nodes(2,:) == 0.5 & grid.nodes(3,:) == 0.5);
# [x,order] = sort(grid.nodes(1,alongX));
#
# U = solve(grid, incompress, C3D8());

#
# hold on
# plot(x,U(2,alongX(order)),'--','LineWidth',lw,'Color','b');
# hold off
#
# U = solve(grid, incompress, C3D8M());
#
# hold on
# plot(x,U(2,alongX(order)),'--','LineWidth',lw,'Color','r');
# hold off
#
# grid = loadFrom('setk_acc.4ekm'); % Загрузка сетки из файла
# alongX = find(grid.nodes(2,:) == 0.5 & grid.nodes(3,:) == 0.5);
# [x,order] = sort(grid.nodes(1,alongX));
#
# U = solve(grid, incompress, C3D8());
#
# hold on
# plot(x,U(2,alongX(order)),'-','LineWidth',lw,'Color','b');
# hold off
#
# U = solve(grid, incompress, C3D8M());
#
# hold on
# plot(x,U(2,alongX(order)),'-','LineWidth',lw,'Color','r');
# hold off
#
# ylim([-0.08,0])
# leg = legend('Полилинейный, редкая сетка','Моментный, редкая сетка','Полилинейный, густая сетка','Моментный, густая сетка')
# title('incompress');
# set(leg, 'FontName', 'Times New Roman', 'FontSize', 14);
# xlabel('Координата вдоль оси бруса, см', 'FontName', 'Times New Roman', 'FontSize', 14,'FontWeight', 'bold', 'FontAngle', 'italic');
# ylabel('Прогиб, см', 'FontName', 'Times New Roman', 'FontSize', 14,'FontWeight', 'bold', 'FontAngle', 'italic');

# printNode = find(grid.nodes(1,:) == 10 & grid.nodes(2,:) == 0 & grid.nodes(3,:) == 0);
# vis = Visualizer(grid); % Посмотреть сетку
# vis.showDisplacements(U,100); % Посмотреть перемещения
# vis.showField(stress(1,:)) % Посмотреть напряжение SYY
# disp(U(1,printNode));
# disp(U(2,printNode));
# disp(U(3,printNode));
end

function bc = Boundary(grid)
    right = find(grid.nodes(1,:)==0); % Номера узлов на правом конце
    bc=[right * 3-2; right * 3-1; right * 3]; % Граничные условия, закрепления по XYZ
end

function force = ExForce(grid,P)
    B = find(grid.nodes(3,:) == 1); % Номера узлов на нагружаемой грани
    force = zeros(size(grid.nodes));   % Размер вектора внешних сил = количество степеней свободы
    h = abs(grid.nodes(1,1) - grid.nodes(1,2)); % Сетка из квадратов
    force(3,B) = -h*h*P;

    C = (grid.nodes(1,B) == 0 | grid.nodes(1,B) == 10); % Логическое условие, лежит ли узел на грани
    D = (abs(grid.nodes(2,B)) < 1e-6 | abs(grid.nodes(2,B) - 1) < 1e-6);
    force(3,B(C)) = force(3,B(C))* 0.5; % Узлы на гранях испытывают половину нагрузки,
    force(3,B(D)) = force(3,B(D))* 0.5; % а на углах - только четверть
end

function U = solve(grid, material, element)
    P = 1e-5; % Задание внешнего давления: 1 МПа

    bc = Boundary(grid); % Задание граничных условий
    force = ExForce(grid,P); % Задание правой части

    # problem = SolidElasticity(C3D8M(), mat);
    problem = SolidElasticity(element, material); % Задаём проблему - трёхмерная с текущим элементом, с данным материалом

    asm = Assembler(problem, grid); % Задаём сборщик матриц

    solver = Static(asm); % Инициализируем решатель
    solver.applyBC(bc); % применяем граничные условия
    solver.step(force); % решаем задачу
    U = solver.U; % Забираем результат расчёта
    U = reshape(U,3,[]); % Возвращаем матрицу [Ux;Uy;Uz]
end
