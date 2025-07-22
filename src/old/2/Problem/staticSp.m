function displacement = staticSp(grid, graphic_handle,elem_idx)
    cd ../Material;
    mat = ESP;
    cd ../Element;
    el = HM24(mat);
    cd ../;

    [K,M] = el.globalCompute(grid);

    gravity = 980; %[cm/sec^2]
    rho = 1.e-09;
    n = size(grid.mesh,1);
    q = 0 * spdiags(M); %gravity

    for i = 1:size(grid.elem,1)
        nodes = grid.mesh(grid.elem(i,:),:);
        norms = vecnorm(nodes,2,2);

        ind_zero = find(abs(norms - 20) < 0.01);
        if size(ind_zero,1) == 4
            sqare = norm(cross(nodes(ind_zero(2),:) - nodes(ind_zero(1),:), nodes(ind_zero(3),:) - nodes(ind_zero(1),:)));
            sqare = rho * gravity * sqare;
            tmp = grid.elem(i,ind_zero);
            for k=1:size(ind_zero,1)
                V = nodes(ind_zero(k),:)';
                q(3 * tmp(k) - 2: 3 * tmp(k)) -= 1 * sqare * V / norms(ind_zero(k));
            end
        end
    end
    disp('Assembled force');

    at = [ 3 * find(grid.mesh(:,1) == 0) - 2; 3 * find(grid.mesh(:,2) == 0) - 1;3 * find(grid.mesh(:,3) == 0)];
    [q,K] = el.attach(at,q,K);
    disp('Attached');
    opts.SYM = true;
    opts.POSDEF = true;
    u = linsolve(K,q,opts);
    displacement = reshape(u,3,[])';

    c_d = zeros(length(elem_idx),1);
    for j = 1:length(elem_idx)
        tmp = repelem(3*grid.elem(elem_idx(j),:),3) + repmat(-2:0,1,8);
        c_d(j) = el.stressInt(grid.points(elem_idx(j)),u(tmp));
    end
    set(graphic_handle,"vertices",grid.mesh + displacement);
    set(graphic_handle,"facevertexcdata",c_d);
end
