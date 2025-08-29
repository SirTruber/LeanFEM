function result = Problem
    model = Model(Mesh.import('../../grid/dirka.4ekm'));

    attach = Boundary(model.geometry.mesh);
    force = Force(model.geometry.mesh);

    result = sol(model,attach,force);
%     grid = Mesh.import('../../grid/dirka.4ekm');
%     mat = MaterialDB().materials('steel');
%     el = HM24(mat);

%     [K, M] = el.assemble(grid);

%     attach = Boundary(grid.mesh);
%     force = Force(grid.mesh);

%     [quads, quadToHexas] = generateQuads(grid.mesh.hexas);
%     Kurant = 10;
%     dt = Kurant * 0.1308 / mat.waveSpeed
%     omega = 0.001;
%
%     solver = Static(attach,K);
%
%     solver.step(force);
%     solver = Newmark(dt,attach,K,M,zeros(3*grid.numVertices,1),force);
%     count = 0.5/omega/dt
%     h = plotMesh(grid.mesh);
%     xlim([-10 10]);
%     ylim([-2 18]);
%     zlim([-9 11]);
%     clim([0 0.2]);
%     colormap turbo;
%     colorbar;
%     set(h,'facecolor','interp');
%     DelayTime = 10 / count;
%     for i = 1:count
%         t = i * dt;
%         disp(100*i/count);
%         mod = sin(pi* omega * t);
%         solver.step(force * mod);
%         pos = reshape(grid.mesh.nodes(:) + solver.U,3,[]);
%         set(h,'vertices',pos');
%         stress = arrayfun(@(i) VonMises(el, grid.mesh.points(i), getU(solver.U, grid.mesh.hexas(:,i))), quadToHexas);
%         set(h, 'FaceVertexCData',stress');
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
    q(3*q_ind - 2) = -1e-1; % Примерно 100 тонн-сил
end

function stress = VonMises(element, points, U)
    S = element.elasticity * element.computeGradient(points + reshape(U,3,[])) * U;
    stress = 1/sqrt(2) * sqrt((S(1) - S(2))^2 + (S(2) - S(3))^2 + (S(3) - S(1))^2 + 6*(S(4)^2 + S(5)^2 + S(6)^2));
end

function ret = getU(U, nodes)
    ind = 3 * repelem(nodes, 3, 1) - repmat([2;1;0],8,1);
    ret = U(ind);
end

function [quads,quadToHexas] = generateQuads(hexas)
            a = int32( ...
           [1 2 3 4;...  % Грань 1 (нижняя)
            5 8 7 6;...  % Грань 2 (верхняя)
            1 5 6 2;...  % Грань 3 (передняя)
            4 3 7 8;...  % Грань 4 (задняя)
            2 6 7 3;...  % Грань 5 (правая)
            1 4 8 5]);    % Грань 6 (левая)

            quads = reshape(hexas(a',:),4,[]); %Собираем все грани гексаэдров

            [~,ida,idx] = unique(sort(quads)',"rows","stable"); %Оставляем только уникальные
            count = accumarray(idx,1);

            quadToHexas = repelem(1:size(hexas,2),6);
            quads = quads(:,ida(count == 1)); % И которые встречаются только один раз
            quadToHexas = quadToHexas(ida(count == 1));
        end
