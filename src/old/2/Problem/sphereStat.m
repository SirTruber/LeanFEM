function displacement = sphereStat(grid)
    mat = Material();
    mat.density = 1e-11;
    mat.young_module = 0.1;
    el = HM24(mat);
    step = 24 * 24;
    n = size(grid.elem,1);
    i_trip = zeros(step * n,1);
    j_trip = zeros(step * n,1);
    ij_trip = zeros( 24 * n,1);
    v_trip = zeros(step * n,1);
    m_trip = zeros(24 * n,1);
    for i=1:n
        el.changeCell(grid.points(i));
        tmp = repmat(repelem(3*grid.elem(i,:),3) + repmat(int32(-2:0),1,8),24,1);
        i_trip((i - 1) * step + 1:i * step,1) = reshape(tmp,1,[]);
        j_trip((i - 1) * step + 1:i * step,1) = reshape(tmp.',1,[]);
        v_trip((i - 1) * step + 1:i * step,1) = reshape(el.stiffness(),1,[]);

        ij_trip((i - 1) * 24 + 1:i * 24,1) = tmp(1,:);
        m_trip((i - 1) * 24 + 1:i * 24,1) = el.mass();
    end
    K = sparse(i_trip,j_trip,v_trip);
    M = sparse(ij_trip,ij_trip,m_trip);

    disp('Assembled matrix');
    gravity = 980; %[cm/sec^2]
    rho = 1.e-09;
    n = size(grid.mesh,1);
    q = gravity * spdiags(M); %gravity

    for i = 2500:size(grid.elem,1)
        nodes = grid.mesh(grid.elem(i,:),:);
        norms = vecnorm(nodes,2,2);

        ind_zero = find(abs(norms - 20) < 0.01);
        if size(ind_zero,1) == 4
            sqare = norm(cross(nodes(ind_zero(2),:) - nodes(ind_zero(1),:), nodes(ind_zero(3),:) - nodes(ind_zero(1),:)));
            sqare = rho * gravity * sqare;
            tmp = grid.elem(i,ind_zero);
            for k=1:size(ind_zero,1)
                V = nodes(ind_zero(k),:)';
                q(3 * tmp(k) - 2: 3 * tmp(k)) -= V(3) * sqare * V / norms(ind_zero(k));
            end
        end
    end
    disp('Assembled force');
    for i = 1:n
        if (grid.mesh(i,1) == 0)
            left = 3 * (i - 1);
            right = 3 * (n - i) + 2;
            q(left + 1) = 0;
            K11 = K(1:left,1:left);
            K13 = K(1:left,left+2:end);
            K33 = K(left+2:end,left+2:end);
            K = [K11 zeros(left,1) K13;
                 zeros(1,left) speye(1) zeros(1,right);
                 K13' zeros(right,1) K33];
        end
        if (grid.mesh(i,2) == 0)
            left = 3 * (i - 1) + 1;
            right = 3 * (n - i) + 1;
            q(left + 2) = 0;
            K11 = K(1:left,1:left);
            K13 = K(1:left,left+2:end);
            K33 = K(left+2:end,left+2:end);
            K = [K11 zeros(left,1) K13;
                 zeros(1,left) speye(1) zeros(1,right);
                 K13' zeros(right,1) K33];
        end
        if (grid.mesh(i,3) == 0)
            left = 3 * (i - 1) + 2;
            right = 3 * (n - i);
            q(left + 3) = 0;
            K11 = K(1:left,1:left);
            K13 = K(1:left,left+2:end);
            K33 = K(left+2:end,left+2:end);
            K = [K11 zeros(left,1) K13;
                 zeros(1,left) speye(1) zeros(1,right);
                 K13' zeros(right,1) K33];
        end

    end
    disp('Attach construction');
    opts.SYM = true;
    opts.POSDEF = true;
    u = linsolve(K,q,opts);
    disp('Solved');
    displacement = reshape(u,3,[])';
    grid.show(displacement), xlim([0 21]),ylim([0 21]),zlim([0 21]);
end
