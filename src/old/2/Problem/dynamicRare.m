function displacement = dynamic(grid,graphic_handle,elem_idx)
    cd ../Material;
    mat = Steel;

    cd ../Element;
    el = TL12(mat);
    cd ../;

    [K,M] = el.globalCompute(grid);
    time_step = 50 * grid.CLF / mat.waveSpeed;

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

    len = abs(grid.mesh(1,3) - grid.mesh(end,3));
    K = K + a0 * M ;%+ a1 * D;
    n = size(grid.mesh,1);
    q = zeros(3 * n,1);
    q(3 * find(grid.mesh(:,3) == 10) - 1) = 1 / len / 25;
    at = find(grid.mesh(:,3) == 0);
    at = [at ; reshape(grid.elem(:,[1 3 6 8]),[],1)];
    at = unique(at);
    at = repelem(3*at,3) + repmat((-2:0)',length(at),1);
    [q,K] = el.attach(at,q,K);

    u_p = zeros(3 * size(grid.mesh,1),1);
    v_p = zeros(3 * size(grid.mesh,1),1);
    a_p = zeros(3 * size(grid.mesh,1),1);

    u = zeros(3 * size(grid.mesh,1),1);
    v = zeros(3 * size(grid.mesh,1),1);
    a = zeros(3 * size(grid.mesh,1),1);
    det(K)
    dK = chol(K);

    n = 25000;
    a_i = zeros(n,1);
    v_i = zeros(n,1);
    u_i = zeros(n,1);
    v_d = [];
    c_d = zeros(length(elem_idx),1);
    for i=1:n
        u_p = u;
        v_p = v;
        a_p = a;
        r = q + M * (a0*u + a2 * v + 2 * a ) ;%+ D * (a1 * u + 2 * v + a3 * a);
        r = el.attach(at,r);
        u_t = dK\(dK'\r);

        a = a4*(u_t - u_p) + a5 * v_p + a6 * a_p;
        v = v_p + a7 * (a + a_p);
        u = u_p + time_step * v_p + a8 * (a + 2 * a_p);

        for j = 1:length(elem_idx)
            tmp = repelem(3*grid.elem(elem_idx(j),:),3) + repmat(-2:0,1,8);
            c_d(j) = el.stressInt(grid.points(elem_idx(j)),u(tmp));
        end
        displacement = reshape(u,3,[])';
        set(graphic_handle,"vertices",grid.mesh + displacement);
        set(graphic_handle,"facevertexcdata",c_d);
        drawnow
%         img = print('-RGBImage');
%         imwrite(img, '../img/stick.gif','DelayTime',.0005,'Compression','bzip','WriteMode','Append');
%        a_i(i,1) = a(1013 * 3 - 1);
%        v_i(i,1) = v(1013 * 3 - 1);
%        u_i(i,1) = u(1013 * 3 - 1);
    end
%    t_i = linspace(0,n * time_step,n);

%      subplot(3,1,1);
%      plot(t_i,a_i);
%      title('Plot 1');

%     subplot(3,1,2);
%    plot(t_i,v_i / max(v_i));
%    title(['Velocity for point (' num2str(grid.mesh(1013,:)) ')']);

%     subplot(3,1,3);
%     plot(t_i,u_i);
%     title('Plot 3');

%     pkg load signal;
%     mx = min(-u_i);
%     [ym,xm] = findpeaks(-u_i - mx, 'MinPeakHeight', -mx);
%     diff(diff(ym))
%     diff(diff(xm) * time_step)
end
