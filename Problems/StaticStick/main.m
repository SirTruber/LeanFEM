function main()
cd ../core;
% Препроцессор
grid = loadFrom('../../grid/setk_b_t.4ekm');
ind = grid.generateQuads();
viz = Visualizer(grid);
xlim([-2 2])
ylim([-2 2])
zlim([0 11])
% colorbar;
% caxis([0 200]);
view(120,15);
mat = MaterialDB().materials('steel');
el = HM24(mat);
stress = StressCalculator(grid,el,ind);
K = el.assemble(grid);
attach = Boundary(grid);
q = Force(grid);
% Процессор
solver = Static(attach, K, q);
U = solver.U;

%Постпроцессор
cd ../StaticStick;
% viz.showForce(q,-100);
% viz.showAttach(find(grid.nodes(:,3) == 0 | grid.nodes(:,3) == 10));
% viz.writePNG('nondeform.png');
viz.showDisplacements(U,100);

stress = zeros(numel(ind),1);
for i = 1:numel(ind)
    stress(i) = 1/sqrt(2) * sqrt((S(1,i) - S(2,i))^2 + (S(2,i) - S(3,i))^2 + (S(3,i) - S(1,i))^2 + 6*(S(4,i)^2 + S(5,i)^2 + S(6,i)^2));
end
S = stress.VonMises(U);
set(viz.patchHandle.mesh,'FaceVertexCData', S);
% viz.writePNG('deform.png');
end

function attach = Boundary(grid)
    bottom = find(grid.nodes(:,3) == 0 | grid.nodes(:,3) == 10);
    bottom = 3 * repelem(bottom,3) - repmat([2;1;0],size(bottom,1),1);
    attach = ConstraintData();
    attach.nodes = unique(bottom);
    attach.values = zeros(size(attach.nodes));
end

function q = Force(grid)
    q = zeros(size(grid.nodes));
    q_ind = find(grid.nodes(:,3) > 4 & grid.nodes(:,2) == 1 & (grid.nodes(:,3) < 6));
    disp(numel(q_ind));
    q(q_ind,2) = -0.1*2/numel(q_ind);
end

