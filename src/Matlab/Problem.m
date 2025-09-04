function result = Problem
    model = Model(Mesh.import('../../grid/dirka.4ekm'));

    model.changeTask();
    attach = Boundary(model.geometry.mesh);
    model.addPressure([521:3:542,546],1e-4);

    result = sol(model,attach);
%     grid = Mesh.import('../../grid/dirka.4ekm');
%     mat = MaterialDB().materials('steel');
%     el = HM24(mat);

%     [K, M] = el.assemble(grid);

%     attach = Boundary(grid.mesh);

%     force = Force(grid.mesh);

%     Kurant = 10;
%     dt = Kurant * 0.1308 / mat.waveSpeed
%     omega = 0.001;
%
%     solver = Static(attach,K);
%
%     solver.step(force);
%     solver = Newmark(dt,attach,K,M,zeros(3*grid.numVertices,1),force);
%     count = 2/omega/dt
%     h = plotMesh(grid.mesh);

%     clim([0 250]);
%     colormap jet;
%     colorbar;
%     set(h,'facecolor','interp');
%     set(h, 'edgecolor','none');
%     DelayTime = 10 / count;
%     for i = 1:count
%         t = i * dt;
%         disp(100*i/count);
%         mod = sin(pi* omega * t)
%         solver.step(force * mod);
%         pos = reshape(grid.mesh.nodes(:) + solver.U,3,[]);
%         set(h,'vertices',pos');
%         stress = 1e5 * VonMisesStress(el,grid.mesh,solver.U);
%         stress = arrayfun(@(i) VonMises(el, grid.mesh.points(i), getU(solver.U, grid.mesh.hexas(:,i))), quadToHexas);
%         set(h, 'FaceVertexCData',stress);
%         drawnow;
% %         frame = getframe();
% %         im = frame2im(frame);
% %         [imind, cm] = rgb2ind(im);
% %
% %         imwrite(imind, cm, 'implicite.gif', 'gif', 'WriteMode', 'append', 'DelayTime', DelayTime);
%     end
%     disp(count * dt);
end

function attach = Boundary(mesh)
    left = 3 * find(mesh.nodes(1,:) == -9);
    left = [left - 2, left - 1, left];

    allZ = 1:size(mesh.nodes,2);

    allZ = 3 * allZ;

    front = 3 * find(mesh.nodes(2,:) == 0) - 1;

    BC = unique([front, left, allZ]);

    attach = unique(BC);
%     attach = ConstraintData();
%     attach.nodes = unique(BC);
%     attach.values = zeros(size(attach.nodes));
end

function q = Force(mesh)
    q = zeros(3 * size(mesh.nodes,2),1);
    q_ind = find(mesh.nodes(1,:) == 9);
    q_edge = 3 * find(mesh.nodes(2,:) == 0 | mesh.nodes(2,:) == 9) - 2;
    q(3*q_ind - 2) = -5e-4; % Примерно 0.5 тонн-сил
    q(q_edge) = q(q_edge) / 2;
end

function vonMises = VonMisesStress(el, mesh, U)
        n = size(mesh.nodes,2);
        m = size(mesh.hexas,2);

        stress = zeros(6,n);

        [~, VE] = mesh.volume;
        weight = zeros(1,n);
        for i=1:m
            nodes = mesh.hexas(:,i)';

            weight(nodes) = weight(nodes) + VE(i);

            stressEl = el.elasticity * el.computeGradient(mesh.points(i)) * U(NodesSub2ind(nodes));

            stress(:,nodes) = stress(:,nodes) + stressEl(1:6) * VE(i);
        end
        stress = stress ./ weight;
    vonMises = sqrt(0.5 * ((stress(1,:) - stress(2,:)).^2 + (stress(2,:) - stress(3,:)).^2 + (stress(3,:) - stress(1,:)).^2 + 6 * (stress(4,:).^2 + stress(5,:).^2 + stress(6,:).^2)))';
end

function ind = NodesSub2ind(sub)
    ind = 3 * repelem(sub,1,3) - repmat([2,1,0],1,numel(sub));
end

function ret = getU(U, nodes)
    ind = 3 * repelem(nodes, 3, 1) - repmat([2;1;0],8,1);
    ret = U(ind);
end
