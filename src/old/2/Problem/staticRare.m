function displacement = staticRare(grid, graphic_handle,elem_idx)
    cd ../Material;
    mat = Steel;
    cd ../Element;
    el = TL12(mat);
    cd ../;

    K = el.globalCompute(grid);

    n = size(grid.mesh,1);
    q = zeros(3 * n,1);
    for i = 1:n
        if (grid.mesh(i,2) == 1 && (grid.mesh(i,3) >= 4 || grid.mesh(i,3) <= 6))
            q(3*i - 1) = 1/9;
        end
        if (grid.mesh(i,3) == 0 || grid.mesh(i,3) == 10)
            left = 3 * i - 3;
            right = 3 * (n - i);
            q(left + 1:left+3) = 0;
            K11 = K(1:left,1:left);
            K13 = K(1:left,left+4:end);
            K33 = K(left + 4:end,left + 4:end);
            K = [K11 zeros(left,3) K13;
                 zeros(3,left) speye(3) zeros(3,right);
                 K13' zeros(right,3) K33];
        end
    end

    n = size(grid.elem,1);
    core = [2 4 5 7];
    for i = 1:n
        for j = 1:4
            left = 3 * grid.elem(i,core(j)) - 3;
            right = 3 * (size(grid.mesh,1) - grid.elem(i,core(j)));
            q(left + 1:left+3) = 0;
            K11 = K(1:left,1:left);
            K13 = K(1:left,left+4:end);
            K33 = K(left + 4:end,left + 4:end);
            K = [K11 zeros(left,3) K13;
                 zeros(3,left) speye(3) zeros(3,right);
                 K13' zeros(right,3) K33];
        end
    end

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
