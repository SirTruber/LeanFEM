function zadacha_brusHM24
grid = loadFrom('brus.4ekm'); % Загрузка сетки из файла

right = find(grid.nodes(:,1)==0); % Номера узлов, которые должны быть закреплены по Y
left = find(grid.nodes(:,1)==10);

leftup = find(grid.nodes(:,1)==10 & grid.nodes(:,3)==1);
leftdown = find(grid.nodes(:,1)==10 & grid.nodes(:,3)==0);
leftright = find(grid.nodes(:,1)==10 & grid.nodes(:,2)==1);
leftleft = find(grid.nodes(:,1)==10 & grid.nodes(:,2)==0);
                                             %(:,3)= взять третью координату у всех узлов 
bc=[right * 3-2, right * 3-1, right * 3]; % Граничные условия

P= 0.5; 
force = zeros(size(grid.nodes));   %РАЗМЕР ВЕКТОРА ВНЕШНИХ СИЛ = КОЛИЧЕСТВО СТЕПЕНЕЙ СВОБОДЫ

force(left,2) = 0.25 * 0.25 * P;

edge = [leftright;leftleft];
force(edge,:) = force(edge,:)* 0.5;

edge = [leftup;leftdown];
force(edge,:) = force(edge,:)* 0.5;

steel = MaterialDB().materials('steel'); % Указываем материал
fe1 = POLY24(steel); % Указываем тип конечного элемента
K1 = fe1.assemble(grid); % Собираем глобальную матрицу жесткости
solver1 = Static(bc,K1); % Инициализируем решатель
solver1.step(force); % Решаем задачу
U1 = solver1.U; % Забираем результат расчёта
viz=Visualizer(grid); % Создаем визуализатор
viz.showDisplacements(U1,1); % Передаем вычисленное значение перемещений
U1=reshape(U1,3,[]);



