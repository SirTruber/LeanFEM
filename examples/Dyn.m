function Dyn
grid = generateCube(100,1,1,40,4,4); % Загрузка сетки из файла
# F = UnitConverter.N_to_force_system(10);%1e-6; % Задание внешней силы: 10 Н
F = UnitConverter.MPa_to_pressure_system(0.01);
bc = Boundary(grid); % Задание граничных условий
force = ExForce(grid,F); % Задание правой части

grid.materialID(1:grid.numElements()) = 1;
material = {Steel()}; % Тип материала

problem = SolidElasticity(C3D8M());
asm = Assembler(problem, grid, material);
%feM = C3D8M(steel); % Тип конечного элемента - моментный
%feM.param = 5.416;
%feP = C3D8(steel); % Тип конечного элемента - моментный

# umax = F*100^3/3/steel.youngModule*12
kurant = 10;

dt = kurant *  grid.minimalSize() / Steel().PwaveSpeed;
T = 600000;
maxStep = round(T / dt);

# solver = Modal(asm, 5);
solver = Newmark(dt,asm);
solver.applyBC(bc);
# solver.solve();

IC = zeros(size(force(:)));
solver.applyIC(IC,IC,force(:));
U = zeros(3,grid.numNodes(),maxStep);

for i = 1:maxStep
    solver.step(force);
    U(:,:,i) = reshape(solver.U,3,[]);
end
res = DynamicResult(asm,dt * double(1:maxStep), U);
save result.mat res -mat;
# t = zeros(10,2);
# for i = 1:10
# tic
# [K,M] = assemble(feM,grid); % Собираем глобальную матрицу жесткости
# t(i,1) = toc;
# tic
# [K,M] = assemble(feP,grid); % Собираем глобальную матрицу жесткости
# t(i,2)= toc;
# end

% NM = solve(grid,dt,bc,force,feM);
% NP = solve(grid,dt,bc,force,feP);

% num = 19000;
% t = 0:num;
% figure;
% plot(t*dt,[NM(:,2),NP(:,2)]);
% xlim([0,dt*t(end)]);
% ylim(2*[-1,1]);

% xlabel("t, мкс");
% ylabel("U, см");
% legend("Моментный","Полилинейный");
end

function bc = Boundary(grid)
    minRight = min(grid.nodes(1,:));
    right = find(grid.nodes(1,:) == minRight); % Номера узлов на правом конце
    bc=[right * 3-2; right * 3-1; right * 3]; % Граничные условия, закрепления по XYZ
end

% function force = ExForce(grid,F)
%     B = grid.nodes(3,:)==100; % Номера узлов на левом конце
%     C = grid.nodes(1,:)==0 | grid.nodes(1,:)==1;
%     D = grid.nodes(2,:)==0 | grid.nodes(2,:)==1;
% 
%     dS = 1/4/4;
%     force = zeros(size(grid.nodes));   % Размер вектора внешних сил = количество степеней свободы
% 
%     force(3,B) = F * dS;
%     force(3,C) = force(3,C) * 0.5;
%     force(3,D) = force(3,D) * 0.5;
% end
function force = ExForce(grid,F)
    tol = 1e-4;
    force = zeros(3,grid.numNodes());   % 3xN_nodes

    a = ...
    [1 2 3 4;...  % Грань 1 (нижняя)
     5 8 7 6;...  % Грань 2 (верхняя)
     1 5 6 2;...  % Грань 3 (передняя)
     4 3 7 8;...  % Грань 4 (задняя)
     2 6 7 3;...  % Грань 5 (правая)
     1 4 8 5];    % Грань 6 (левая)
    for e = 1:grid.numElements()
        elem_nodes = grid.elements(e);
        coords = grid.points(e);
        for f = 1:size(a,1)

            mask = abs(coords(1,a(f,:)) - 50) < 5 + tol & abs(coords(2,a(f,:)) - 0.5) < 0.5 + tol & abs(coords(3,a(f,:))) < tol;
            if all(mask)
                force(:,elem_nodes(a(f,:))) = force(:,elem_nodes(a(f,:))) ...
                    + pressureLoad(coords(:,a(f,:)),F);
            end
        end
    end
    # B = grid.nodes(1,:) == 50 & grid.nodes(2,:) == 0.5 & grid.nodes(3,:) == 0;

    # force(3,B) = F;
end

% function force = ExForce(grid,F)
%     B = find(grid.nodes(3,:)==100); % Номера узлов на левом конце
%     force = zeros(size(grid.nodes));   % Размер вектора внешних сил = количество степеней свободы
% 
%     C = (grid.nodes(2,B) == 0 | grid.nodes(2,B) == 1); % Логическое условие, лежит ли узел на грани
%     D = (grid.nodes(1,B) == 0 | grid.nodes(1,B) == 1);
%     force(3,B) = F *(grid.nodes(1,B) - 0.5); % F = My/l
% 
%     force(3,B(C)) = force(3,B(C))* 0.5; % Узлы на гранях испытывают половину нагрузки,
%     force(3,B(D)) = force(3,B(D))* 0.5; % а на углах - только четверть 
% end

function N = solve(grid,dt,bc,force,fe)
    [K,M] = assemble(fe,grid); % Собираем глобальную матрицу жесткости
    
    solver = Static(bc,K);
    solver.step(force);
    U = solver.U;
    solver1 = Newmark(0.5*dt,bc,K,M,zeros(size(grid.nodes)),force); % Инициализируем решатель
    solver2 = Newmark(dt,bc,K,M,zeros(size(grid.nodes)),force); % Инициализируем решатель
    solver1.U = U;
    solver2.U = U;
    
    fce = zeros(size(grid.nodes));
    B = find(grid.nodes(1,:) == 0.5 & grid.nodes(2,:) == 0.5 & grid.nodes(3,:) == 100);

    U(3*B-1)
    num = 19000;
    N = zeros(num,2);
    % N(1,1) = U(3*B-1);
    N(1,2) = U(3*B-1);
    for i = 1:num
        % tic
        % solver1.step(fce); % Решаем задачу
        % solver1.step(fce); % Решаем задачу
        solver2.step(fce); % Решаем задачу

        % N(i+1,1) = solver1.U(3*B-1);
        N(i+1,2) = solver2.U(3*B-1);
        % toc * num
        % if mod(i,100) == 0
            % U1 = solver1.U; % Забираем результат расчёта
            % U1 = reshape(U1,3,[]); % Возвращаем матрицу [Ux;Uy;Uz]
            % U2 = solver2.U;
            % U2 = reshape(U2,3,[]);

            % plot((0:40) * 2.5,-[U1(1,B)',U2(1,B)']);
            % title(i*dt);
            % pause(1);
        % end
    end
    % t = 0:num;
    % figure;
    % plot(t*dt,N);
    % xlim([0,dt*t(end)]);
    % ylim([-1,1]);
    % legend("Newmark","KN");
    % figure
    % plot(t*dt,P(:,2:3));
    % legend("Newmark","KN");
end
