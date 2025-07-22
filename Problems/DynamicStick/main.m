function main()
run('../../__init__.m');
grid = loadFrom('../../grid/dyn.4ekm');
% viz = Visualizer(grid);
% colorbar;
% xlim([-5.5 5.5])
% ylim([-5.5 5.5])
% zlim([0 11])
% caxis([0 200]);
% view(45,30);

mat = MaterialDB().materials('steel');
el = HM24(mat);
%
% ind = zeros(1,size(grid.quads,1));
% for i = 1:size(grid.quads,1)
%     for j = 1:size(grid.hexas,1)
%         if all(ismember(grid.quads(i, :), grid.hexas(j, :)))
%             ind(i) = j;
%             break;
%         end
%     end
% end
% stress = StressCalculator(grid,el,ind);

n = size(grid.nodes,1);
m = size(grid.hexas,1);

[K,M] = el.assemble(grid);
attach = Boundary(grid);
q = Force(grid);
U_ind = find(grid.nodes(:,1) == 0.5 & grid.nodes(:,2) == 1);
U_ind = 3 * sort(U_ind);
V_ind = 3 * find(grid.nodes(:,1) == 0.5 & grid.nodes(:,2) == 1 & (grid.nodes(:,3) == 100)) - 1;
Kurant = 10;
dt = Kurant * grid.minHeight(1:m) / mat.waveSpeed;
solver10 = Newmark(dt,attach,K,M,zeros(3*n,1),q);
solver20 = Newmark(2*dt,attach,K,M,zeros(3*n,1),q);
count = int64(0.0012 / dt);
V_10 = zeros(1,count * 8);
V_20 = zeros(1,count * 4);
len = 0:40;
len = 2.5 * len;
j1 = 1; j2 = 1;
for i = 1:count
    solver10.step(q);
    V_10(j1++) = solver10.V(V_ind);
    solver20.step(q);
    V_20(j2++) = solver20.V(V_ind);
end
for i = 1:count
    solver10.step(q);
    V_10(j1++) = solver10.V(V_ind);
end
figure
hold on
title('Максимальные и минимальные прогибы стержня')
plot(len,-solver10.U(U_ind),'color','m');
plot(len,-solver20.U(U_ind),'color','g');
for i = 1:count
    solver10.step(q);
    V_10(j1++) = solver10.V(V_ind);
    solver20.step(q);
    V_20(j2++) = solver20.V(V_ind);
end
for i = 1:count
    solver10.step(q);
    V_10(j1++) = solver10.V(V_ind);
end
plot(len,-solver10.U(U_ind),'color','b');
plot(len,-solver20.U(U_ind),'color','r');
legend("K=10,t=t1","K=20,t=t1","K=10,t=t2","K=20,t=t2",'location',"northwest");
ylabel("Прогибы,см");
hold off
img = print('-RGBImage');
imwrite(img, '1.png');
for i = 1:count
    solver10.step(q);
    V_10(j1++) = solver10.V(V_ind);
    solver20.step(q);
    V_20(j2++) = solver20.V(V_ind);
end
for i = 1:count
    solver10.step(q);
    V_10(j1++) = solver10.V(V_ind);
end
for i = 1:count
    solver10.step(q);
    V_10(j1++) = solver10.V(V_ind);
    solver20.step(q);
    V_20(j2++) = solver20.V(V_ind);
end
for i = 1:count
    solver10.step(q);
    V_10(j1++) = solver10.V(V_ind);
end
figure
hold on
title('Скорости на свободном конце стержня')
t1 =dt * double(1:(8*count));
t2 =dt * 2 * double(1:(4*count));
to_norm = max([V_10,V_20]);
plot(t1,V_10/to_norm);
plot(t2,V_20/to_norm);
legend("K=10","K=20");
xlabel("t,с")
hold off
img = print('-RGBImage');
imwrite(img, '2.png');
end

function attach = Boundary(grid)
    bottom = find(grid.nodes(:,3) == 0);
    bottom = 3 * repelem(bottom,3) - repmat([2;1;0],size(bottom,1),1);

    attach = ConstraintData();
    attach.nodes = unique(bottom);
    attach.values = zeros(size(attach.nodes));
end

function q = Force(grid)
    q = zeros(3 * size(grid.nodes,1),1);
    q_ind = find(grid.nodes(:,1) == 0.5 & grid.nodes(:,2) == 0 & (grid.nodes(:,3) == 50));
    q(3*q_ind - 1) = 20;
end

