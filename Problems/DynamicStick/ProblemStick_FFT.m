function ProblemStick_FFT()
grid = loadFrom('../../grid/dyn.4ekm');

mat = MaterialDB().materials('steel');
el = HM24(mat);

n = size(grid.nodes,1);
m = size(grid.hexas,1);

[K,M] = el.execute(grid);
attach = Boundary(grid);
q = Force(grid);
U_ind = find(grid.nodes(:,1) == 0.5 & grid.nodes(:,2) == 1);
U_ind = 3 * sort(U_ind);
V_ind = 3 * find(grid.nodes(:,1) == 0.5 & grid.nodes(:,2) == 1 & (grid.nodes(:,3) == 100)) - 1;
Kurant = 10;
dt = Kurant * grid.minHeight(1:m) / mat.waveSpeed;
solver = Newmark(dt,attach,K,M,zeros(3*n,1),q);
count = int64(1.0 / dt);
disp(count);
U = zeros(1,count);
len = 0:40;
len = 2.5 * len;
j1 = 1; j2 = 1;
for i = 1:count
    solver.step(q);
    U(j1++) = solver.U(V_ind);
end
figure
hold on
title('Перемещения на свободном конце стержня')
t = dt * double(1:count);
plot(t,U);
xlabel("t,с")
hold off

f = fft(U);
a = abs(f);
figure;
plot(1/dt*t,a);
ax = gca();
set(ax,'yscale','log');
set(ax,'xlim',[1 count/2]);
img = print('-RGBImage');
imwrite(img, 'spectr.png');
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
    disp(size(q_ind));
    q(3*q_ind - 1) = 20;
end

