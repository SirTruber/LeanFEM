function pipe()
run('../../src/setup.m'); % Добавить пути к src

P = 50*1e-5; % Задание внешнего давления: 100 МПа
p = 10 *1e-5; % Задание внутреннего давления: 10 МПа
R = 5;        % Внешний радиус
r = 1;        % Внутренний радиус

nr = 100;      % Число разбиений вдоль радиуса
na = 20;      % Число разбиений вдоль угла
dl = 0.5 * pi /na; % Дифференциал дуги

grid = ringGrid(r,R,na,nr); % Создание сетки на лету

bc = Boundary(grid,na); % Задание граничных условий
force = ExForce(grid,na,p,P,dl); % Задание правой части

steel = Steel(); % Тип материала

fe = C2D4(steel); % Тип конечного элемента - билинейный

U = solve(grid,bc,force,fe);

[~,stress] = fe.evaluateStrainAndStress(grid,U); % Напряжения однородные. 
vM = fe.vonMises(stress); % Вычисление эквивалентных напряжений Мизеса

vis = Visualizer(grid); % Посмотреть сетку
%vis.showForce([force;zeros(1,grid.numNodes)],-100); % Посмотреть силы
%vis.showDisplacements(UP,100); % Посмотреть перемещения
%vis.showField(stress(1,:)) % Посмотреть напряжение SXX
vis.showField(vM) % Посмотреть напряжение VON
end

function force = ExForce(grid,na,p,P,dl)
    inner = 1:na +1;
    outer = grid.numNodes() - na:grid.numNodes();
    bottom = 1:na+1:grid.numNodes();
    up = na+1:na+1:grid.numNodes();
    edge = intersect([inner,outer],[up,bottom]);

    force = zeros(size(grid.nodes));   % Размер вектора внешних сил = количество степеней свободы

    force(:,inner) = force(:,inner) + p * grid.nodes(:,inner) * dl; 
    force(:,outer) = force(:,outer) - P * grid.nodes(:,outer) * dl; 
    force(:,edge) = force(:,edge) * 0.5; % Узлы на гранях испытывают половину нагрузки
    force = force(1:2,:);
end

function U = solve(grid,bc,force,fe)
    K = assemble(fe,grid); % Собираем глобальную матрицу жесткости
    solver = Static(bc,K); % Инициализируем решатель
    solver.step(force); % Решаем задачу
    U = solver.U; % Забираем результат расчёта
    U = reshape(U,2,[]); % Возвращаем матрицу [Ux;Uy]
end

function bc = Boundary(grid,na)
bottom = 1:na+1:grid.numNodes();
up = na+1:na+1:grid.numNodes();

bc = [up*2 - 1, bottom * 2];
end

function grid = ringGrid(rInner, rOuter, nAngle,nRadius)
    numNodesAngle = nAngle + 1;
    numNodesRadius = nRadius + 1;
    numNodes = numNodesAngle * numNodesRadius;
    numElements = nAngle * nRadius;

    angles = linspace(0, 0.5 * pi,numNodesAngle);
    radii = linspace(rInner,rOuter,numNodesRadius);

    nodes = zeros(3,numNodes);
    nodeIDX = 0;
    for ir = 1:numNodesRadius
        r = radii(ir);
        for ia=1:numNodesAngle
            theta = angles(ia);

            x = r * cos(theta);
            y = r * sin(theta);
            z = 0;
            nodeIDX = nodeIDX + 1;
            nodes(:,nodeIDX) = [x;y;z];
        end
    end

    nodeAt = @(ia,ir) (ir - 1) * numNodesAngle + ia;

    quads = zeros(4,numElements, 'int32');
    
    quadIDX = 0;
    for ir = 1:(numNodesRadius - 1)
        for ia = 1:(numNodesAngle -1)
            %  4____3
            %  |    |
            %  |    |
            %  1____2
            % Node1: (ia, ir)
            % Node2: (ia+1,ir)
            % Node3: (ia+1,ir+1)
            % Node4: (ia, ir+1)

            n1 = nodeAt(ia,ir);
            n2 = nodeAt(ia+1,ir);
            n3 = nodeAt(ia+1,ir+1);
            n4 = nodeAt(ia,ir+1);

            quadIDX = quadIDX + 1;
            quads(:,quadIDX) = int32([n1;n2;n3;n4]);
        end
    end
    grid = Grid2D;
    grid.name = 'pipe';
    grid.nodes = nodes;
    grid.quads = quads;
end