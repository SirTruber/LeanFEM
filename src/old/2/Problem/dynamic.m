function displacement = dynamic(grid,graphic_handle,elem_idx)
    cd ../Material;
    mat = Steel;

    cd ../Element;
    el = HM24(mat);
    cd ../;

    n = rows(grid.mesh);
    m = rows(grid.elem);

    at = find(grid.mesh(:,3) == 0 | grid.mesh(:,3) == 10);
    at = sub2ind(size(grid.mesh), repmat(at,1, 3), repmat([1 2 3], numel(at), 1))(:);%attach for x, y, z

    Kurant = 10;
    time_step = Kurant * grid.minHeight(1:m) / mat.waveSpeed


%     beta = 0.5;
%     alpha = 0.25 * (0.5 + beta)^2;
%
%     a0 = 1/alpha/time_step^2
%     a1 = beta / alpha / time_step
%     a2 = 1/alpha/time_step
%     a3 = 0.5 / alpha - 1
%     a4 = beta / alpha - 1
%     a5 = 0.5 * time_step * (beta / alpha - 2)
%     a6 = time_step * (1 - beta)
%     a7 = beta*time_step
%     theta = 1.37;
%
%     a0 = 6/(theta * time_step)^2
%     a1 = 3/(theta * time_step)
%     a2 = 2 * a1
%     a3 = 0.5 * theta * time_step
%     a4 = a0 / theta
%     a5 = -a2 / theta
%     a6 = 1 - 3/theta
%     a7 = 0.5 * time_step
%     a8 = time_step^2 / 6

    [K,M] = el.globalCompute(grid);

%     K = K + a0 * M ;%+ a1 * D;
    K_ef = 1/time_step * M + time_step* K;
    len = abs(grid.mesh(3,1) - grid.mesh(3,end));
    q = zeros(3 * n,1);

    u_p = zeros(3 * n,1);
    v_p = zeros(3 * n,1);
    a_p = zeros(3 * n,1);

    u = zeros(3 * n,1);
    v = zeros(3 * n,1);
    a = zeros(3 * n,1);

    q = zeros(3 * n,1);
    q_ind = find(grid.mesh(:,2) == 1 & (grid.mesh(:,3) >= 4 & grid.mesh(:,3) <= 6))
%     q(sub2ind(size(grid.mesh), q_ind, 2(ones(q_ind,1)))) = 1/len;

    K_ef = el.attach(at,K_ef);
    K_ef = chol(K_ef)
%     K = el.attach(at,K);

%     K = chol(K);
    K2 = 1/time_step - 0.25 * time_step * K;
    n = 250;
%     a_i = zeros(n,1);
    v_i = zeros(n,1);
%     u_i = zeros(n,1);
%     c_d = zeros(length(elem_idx),1);
    for i=1:n
        disp(i);
        u_p = u;
        v_p = v;
%         a_p = a;

        r = q + M * 1/time_step * v_p - K * (0.25 * time_step * v_p + u_p);
        v = K_ef\(K_ef'\r);
        u = u_p + 0.5*time_step*(v + v_p);
%theta willson
%         r = q + M * (a0*u + a2 * v + 2 * a ) ;%+ D * (a1 * u + 2 * v + a3 * a);
%         r = el.attach(at,r);
%         u_t = dK\(dK'\r);
%
%         a = a4*(u_t - u_p) + a5 * v_p + a6 * a_p;
%         v = v_p + a7 * (a + a_p);
%         u = u_p + time_step * v_p + a8 * (a + 2 * a_p);
%         r = q + M * (a0*u + a2 * v + a3 * a ) ;%+ D * (a1 * u + 2 * v + a3 * a);
%         r(at) = 0;
%         u = K\(K'\r);
%         displacement = reshape(u,[],3)';



%         a = a0*(u - u_p) - a2 * v_p - a3 * a_p;
%         v = v_p + a6 * a_p + a7 * a;

%         for j = 1:length(elem_idx)
%             tmp = repelem(3*grid.elem(:,elem_idx(j)),3) + repmat((-2:0)',8,1);
%             c_d(j) = el.stressInt(grid.points(elem_idx(j))',u(tmp));
%         end
%         set(graphic_handle,"vertices",(grid.mesh + displacement)');
%         set(graphic_handle,"facevertexcdata",c_d);
%         drawnow
%         img = print('-RGBImage');
%         imwrite(img, '../img/deformone.gif','DelayTime',.0005,'Compression','bzip','WriteMode','Append');
%        a_i(i,1) = a(1013 * 3 - 1);
       v_i(i,1) = v(1014 * 3 - 1);
%        u_i(i,1) = u(1013 * 3 - 1);
    end
   t_i = linspace(0,n * time_step,n);

%      subplot(3,1,1);
%      plot(t_i,a_i);
%      title('Plot 1');

    subplot(3,1,2);
   plot(t_i, v_i);
   title(['Velocity for point (' num2str(grid.mesh(1014,:)) ')']);

%     subplot(3,1,3);
%     plot(t_i,u_i);
%     title('Plot 3');

%     pkg load signal;
%     mx = min(-u_i);
%     [ym,xm] = findpeaks(-u_i - mx, 'MinPeakHeight', -mx);
%     diff(diff(ym))
%     diff(diff(xm) * time_step)
end
