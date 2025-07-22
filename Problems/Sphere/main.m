function main
run('../../__init__.m');
grid = loadFrom('../../grid/neravnomer_r10_R20.4ekm');
viz = Visualizer(grid);

xlim([0 22])
ylim([0 22])
zlim([0 22])
view(45,15)

q = Force(grid);
viz.showForce(q,-200);

attach = Boundary(grid);

Symetry = [find(grid.nodes(:,1) == 0),find(grid.nodes(:,2) == 0),find(grid.nodes(:,3) == 0)];

viz.showAttach(Symetry);

mat = MaterialDB().materials('ESP');
el = HM24(mat);
K = el.assemble(grid);
solver = Static(attach, K);
solver.step(q);
U = solver.U;
viz.showDisplacements(U,5);
%
% Kurant = 10;
% dt = Kurant * grid.minHeight(1:m) / mat.waveSpeed;
%
% solver = Newmark(dt,attach,K,M,~,q);
% count = 30;
% for i = 1:count
%     solver.step(q);
%     viz.showDisplacements(solver.U,3);
%     drawnow;
%     viz.writeGIF('sp.gif',0.01);
% end
stress = zeros(10,1);
for i = 0:9
    points = grid.points(300 * i + 1);
    dots = repelem(3 * grid.hexas(300*i + 1,:),1,3) + repmat([-2 -1 0],1,8);
    S = el.elasticity * el.grad(points) * U(dots);
    stress(i+1) = 1/sqrt(2) * sqrt((S(1) - S(2))^2 + (S(2) - S(3))^2 + (S(3) - S(1))^2 + 6*(S(4)^2 + S(5)^2 + S(6)^2));
end
ideal = 10.5:0.5:19.5;
ideal = ideal.^(-3);
ideal = 3 *20^3 / 2 /(20^3 - 10^3) * ideal;
%

% disp(ideal);
figure
hold on;
scatter(10.5:1:19.5,10^4 * stress,'r');
plot(10.5:0.5:19.5,10^4 * ideal,'b');
hold off
% U = reshape(U',3,[])';
end

function attach = Boundary(grid)
    SymetryX = find(grid.nodes(:,1) == 0);
    SymetryY = find(grid.nodes(:,2) == 0);
    SymetryZ = find(grid.nodes(:,3) == 0);

    SymetryX = 3 * SymetryX - 2;
    SymetryY = 3 * SymetryY - 1;
    SymetryZ = 3 * SymetryZ;

    Boundary = [SymetryX,SymetryY,SymetryZ];

    attach = ConstraintData();
    attach.nodes = unique(Boundary);
    attach.values = zeros(size(attach.nodes));
end

function q = Force(grid)
    q = zeros(size(grid.nodes,1),3);

    target = @(a) all(abs(vecnorm(a,2,2)' - 20) < 1.5);
    quads_ind = grid.select('quads',target);
    for i = 1:numel(quads_ind)
        nodes_ind = grid.quads(i,:);
        nodes = grid.nodes(nodes_ind,:);
        V = cross(nodes(2,:) - nodes(1,:), nodes(3,:) - nodes(1,:));
        scale = 0.5*pi*20^2 / 331 * 0.0001; %10 KPa
        for j = 1 : numel(nodes_ind)
            q(nodes_ind(j),:) += V /norm(V) * scale;
        end
    end
end
