function displacement = sphereDyn(grid)
    mat = Material();
    mat.density = 1e-11;
    mat.young_module = 0.1;
    time_step = 10000;
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
        time_step = min([time_step el.minHight]);
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

    for i = 2700:size(grid.elem,1)
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

    time_step = 10 * time_step / mat.waveSpeed();

    disp(time_step);
    theta = 1.4;

    a0 = 6/(theta * time_step)^2
    a1 = 3/(theta * time_step)
    a2 = 2 * a1
    a3 = 0.5 * theta * time_step
    a4 = a0 / theta
    a5 = -a2 / theta
    a6 = 1 - 3/theta
    a7 = 0.5 * time_step
    a8 = time_step^2 / 6

    K = K + a0 * M ;%+ a1 * D;
    n = size(grid.mesh,1);

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
            q(left + 1) = 0;
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
            q(left + 1) = 0;
            K11 = K(1:left,1:left);
            K13 = K(1:left,left+2:end);
            K33 = K(left+2:end,left+2:end);
            K = [K11 zeros(left,1) K13;
                 zeros(1,left) speye(1) zeros(1,right);
                 K13' zeros(right,1) K33];
        end

    end
    disp('Attach construction');
    u_p = zeros(3 * size(grid.mesh,1),1);
    v_p = zeros(3 * size(grid.mesh,1),1);
    a_p = zeros(3 * size(grid.mesh,1),1);

    u = zeros(3 * size(grid.mesh,1),1);
    v = zeros(3 * size(grid.mesh,1),1);
    a = zeros(3 * size(grid.mesh,1),1);

    dK = chol(K);

    n = 150;
    a_i = zeros(n,1);
    v_i = zeros(n,1);
    u_i = zeros(n,1);
    v_d = [];
    for i=1:n
        disp(i);
        u_p = u;
        v_p = v;
        a_p = a;
        r = q + M * (a0*u + a2 * v + 2 * a ) ;%+ D * (a1 * u + 2 * v + a3 * a);
        for j = 1:size(grid.mesh,1)
            if (grid.mesh(i,1) == 0)
                r(3 * (i - 1) + 1) = 0;
            end
            if (grid.mesh(i,2) == 0)
                r(3 * (i - 1) + 2) = 0;
            end
            if (grid.mesh(i,3) == 0)
                r(3 * (i - 1) + 3) = 0;
            end
        end
        u_t = dK\(dK'\r);

        a = a4*(u_t - u_p) + a5 * v_p + a6 * a_p;
        v = v_p + a7 * (a + a_p);
        u = u_p + time_step * v_p + a8 * (a + 2 * a_p);


        grid.show(reshape(u,3,[])'), xlim([0 21]),ylim([0 21]),zlim([0 21]);
        img = print('-RGBImage');
        imwrite(img, 'sphereDyn.gif','DelayTime',.0001,'Compression','bzip','WriteMode','Append');
    end
    displacement = reshape(u,3,[])';
    grid.show(displacement), xlim([0 21]),ylim([0 21]),zlim([0 21]);
end
