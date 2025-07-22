function displacement = static(grid, graphic_handle,elem_idx)
    cd ../Material;
    mat = Steel;
    cd ../Element;
    el = HM24(mat);
    cd ../;

    n = rows(grid.nodes);

    len = abs(grid.nodes(1,3) - grid.nodes(end,3));

    at = find(grid.mesh(:,3) == 0 | grid.mesh(:,3) == 10);
    at = sub2ind(size(grid.mesh), repmat(at,1, 3), repmat([1 2 3], numel(at), 1))(:)%attach for x, y, z

    K = el.globalCompute(grid);

    K = el.attach(at,K);

    q = zeros(3 * n,1);
    q_ind = find(grid.mesh(:,2) == 1 & (grid.mesh(:,3) >= 4 & grid.mesh(:,3) <= 6));
    q(sub2ind(size(grid.mesh), q_ind, 2(ones(q_ind,1))) = 1/len;
    q(at) = 0;

    opts.SYM = true;
    opts.POSDEF = true;
    u = linsolve(K,q,opts);
    displacement = reshape(u,3,[])';

%     c_d = zeros(length(elem_idx),1);
%     for j = 1:length(elem_idx)
%         tmp = repelem(3*grid.elem(:,elem_idx(j)),3) + repmat((-2:0)',8,1);
%         c_d(j) = el.stressInt(grid.points(elem_idx(j))',u(tmp));
%     end
    set(graphic_handle,"vertices",(grid.nodes + displacement)');
    set(graphic_handle,"facevertexcdata",c_d);
end
