function result = sol(fem, constraint,mass)
    mat = MaterialDB().materials('steel');
    el = HM24(mat,mass);
    mesh = fem.geometry.mesh;

    box = mesh.box;
    L = max(abs(box(:,1) - box(:,2)))
    omega = mat.waveSpeed / 18;
    T = 1 / omega

    if strcmp(fem.analysisType, 'static')
        s = Static;

        s.assemble(el, fem.geometry);
        K = s.K;
        s.constrain(constraint,[]);

        U = s.solve(fem.load(:));
        R = StaticResult(mesh,el,U);
        m = reshape(fem.load(:) - K*U,3,[]);

        plotSolution(R.mesh,R.vonMisesStress,R.displacement);
    elseif strcmp(fem.analysisType, 'Comb')
    elseif strcmp(fem.analysisType, 'Expl')
        s = Central;
        Kurant = 0.56
        # dt = 0.05
        dt = Kurant * pi/24 / mat.waveSpeed
        # Kurant = 0.56
        # dt = Kurant * 0.1308 / mat.waveSpeed
    elseif strcmp(fem.analysisType, 'Impl')
        s = Newmark;

        dt = T / 32
        # dt = 0.5
        Kurant = mat.waveSpeed * dt / 0.1308
    end
    count = 2*T/dt

    s.setParam(dt);

    s.assemble(el, fem.geometry);
    s.constrain(constraint,[]);

    A0 = zeros(size(s.K,1),1);
    U0 = zeros(size(A0));
    V0 = zeros(size(A0));
    state = s.IC(U0,V0,A0);

    U = zeros(size(s.K,1),1);
    j = 1;
    dt = T/4;
    t = dt * (1:50);
        # h = plotMesh(mesh);
    # axis off
    # clim([0,40]);
    # clabel("MPa");
    # set(h,'edgecolor','none');
    tic
    for i = 1:count
        mod = -sin(2 * pi * omega * s.t);
        state = s.step(state,mod * fem.load(:));
        # R = StaticResult(mesh,el,state(:,1));
        # plotSolution(R.mesh,R.vonMisesStress,R.displacement, 'Scale', 100, 'PlotHandle', h);
        # drawnow
        # if s.t >= t(j)
        #     t(j) = s.t;
        #     U(:,j) = state(:,1);
        #     j+=1;
        # end
    end
    toc
    U(:,j) = state(:,1);
    result = U;
    # h = plotMesh(mesh);
    # clim([0,40]);
    # set(h,'edgecolor','none');
    for i = 1:j-1
        # R = StaticResult(mesh,el,U(:,i));
        # plotSolution(R.mesh,R.vonMisesStress,R.displacement, 'Scale', 100, 'PlotHandle', h);
        # plot((24:-1:0)*180/24,R.vonMisesStress(1:25));
        # title(sprintf('%.2f',t(i)/T))
        # st = max(max(R.vonMisesStress),st);
        # xlim([0,180]);
        # ylim([0,35]);
        # drawnow;
        # img = print('-RGBImage');
        # imwrite(img, 'test.gif','DelayTime',(t(i+1) - t(i))*0.1,'Compression','bzip','WriteMode','Append');
    end
end
