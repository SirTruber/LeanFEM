function sphere
run('../../src/setup.m'); % Добавить пути к src
grid = loadFrom('shar.4ekm'); % Загрузка сетки из файла

Router = 15; % Внешний радиус
Rinner = 5;  % Внутренний радиус

Pouter = 10*1e-5; % Внешнее давление, 10 МПа
plotSolutionA(grid,Rinner,Router,Pouter); 

Pinner = 1*1e-5; % Внутреннее давление, 1 МПа
plotSolutionB(grid,Rinner,Pinner); % Печать результата
end

function plotSolutionA(grid,a,R,P) % Задача о концентрации напряжений у сферической полости
    alongR = [2,13:-1:3,1];
    X = grid.nodes(3,alongR);
    Y = 1e5*P*(1-(a./X).^3);

    steel = Steel;
    
    stressM = solve(grid,C3D8M(steel),R,P);
    stressP = solve(grid,C3D8(steel),R,P);
    
    sM = stressM(3,alongR);
    sP = stressP(3,alongR);
    figure
    plot(X,[Y(:),sM(:),sP(:)]);
    legend("Аналитическое","Численное, моментный","Численное, полилинейный");
end

function plotSolutionB(grid,a,P) % Задача о центре расширения
    alongR = [2,13:-1:3,1];
    X = grid.nodes(3,alongR);
    Y = 1e5*P*(a./X).^3;

    steel = Steel;
    
    stressM = solve(grid,C3D8M(steel),a,-P);
    stressP = solve(grid,C3D8(steel),a,-P);

    sM = stressM(3,alongR);
    sP = stressP(3,alongR);
    figure
    plot(X,[Y(:),sM(:),sP(:)]);
    legend("Аналитическое","Численное, моментный","Численное, полилинейный");
end

function bc = BoundaryCondition(grid) 
eps = 10^-8;
attachX = find(abs(grid.nodes(1,:)) < eps); % Узлы на плоскости X=0
attachY = find(abs(grid.nodes(2,:)) < eps); % Узлы на плоскости Y=0  
attachZ = find(abs(grid.nodes(3,:)) < eps); % Узлы на плоскости Z=0
                                            
bc=[attachX * 3-2, attachY * 3 - 1, attachZ*3]; % Граничные условия
%Фиксируются степени свободы:
                             %   X=0 → закрепление по оси X
                             %   Y=0 → закрепление по оси Y
                             %   Z=0 → закрепление по оси Z
end

function force = load(grid,R,P)
eps = 10^-8;

force = zeros(size(grid.nodes)); % Инициализация узловых нагрузок

for i=1:size(grid.quads,2)   
    points = grid.nodes(:,grid.quads(:,i)); % координаты узлов грани
    r_sqare = sum(points.^2); % Длинна радиус-векторов узлов 
    if any(abs(r_sqare - R^2) > eps) % Если грань не принадлежит R sphere, прерываем тело цикла
        continue;  
    end
    
    %   1 ____ 2
    %   | \    |
    %   |  \   |
    %   |   \  |
    %   |    \ |
    %   |     \|
    %   4 ____ 3
    % S = 1/2(|1_3x3_4| + |1_3x2_3|) = 1/2(|aXb| + |aXc|)
    a = points(:,3) - points(:,1);
    b = points(:,4) - points(:,3);
    c = points(:,3) - points(:,2);
    S = 0.5 * (norm(cross(a,b)) + norm(cross(a,c)));
  
    force(:,grid.quads(:,i)) = force(:,grid.quads(:,i)) + P*points/R * S * 0.25;
end
end

function stress = solve(grid,fe,R,P)
    bc = BoundaryCondition(grid); % Граничные условия
    force = load(grid,R,P); % Нагрузки

    K = assemble(fe,grid); % Собираем глобальную матрицу жесткости
    solver = Static(bc,K); % Инициализируем решатель
    solver.step(force); % Решаем задачу
    U = solver.U; % Забираем результат расчёта
    U = reshape(U,3,[]); % Возвращаем матрицу [Ux;Uy;Uz]

    [~,stress] = fe.evaluateStrainAndStress(grid,U);
end