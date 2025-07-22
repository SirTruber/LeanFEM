grid = loadFrom('../../grid/plate.4ekm');
viz = Visualizer(grid);

n = size(grid.nodes,1);
m = size(grid.hexas,1);

SymetryX = find(grid.nodes(:,1) == 0);
SymetryX = 3 * SymetryX - 2(ones(size(SymetryX)));

SymetryY = find(grid.nodes(:,2) == 0);
SymetryY = 3 * SymetryY - 1(ones(size(SymetryY)));

Boundary = find(grid.nodes(:,2) == 5 | grid.nodes(:,1) == 3.75);
Boundary = 3 * repelem(Boundary,3) - repmat([2;1;0],size(Boundary,1),1);

attach = ConstraintData();
attach.nodes = unique([SymetryX; SymetryY; Boundary]);
attach.values = zeros(size(attach.nodes));

mat = MaterialDB().materials('steel');
el = HM24(mat);
[K,M] = el.execute(grid);

q = zeros(3*n,1);
q(3:3:end) = 0.98(ones(n,1));
q = M * q;  %gravity

Kurant = 10;
dt = Kurant * 0.02 / mat.waveSpeed;

solver = Newmark(dt,attach,K,M,zeros(3*n,1),q);
count = 10;
for i = 1:count
    solver.step(q);
    viz.showDisplacement(solver.U(:,2));
end
