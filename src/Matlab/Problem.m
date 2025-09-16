function result = Problem
    model = Model(Mesh.import('dirka2.4ekm'));

    model.changeTask();
    model.addPressure([521:3:542,546],1e-4);

    mat = MaterialDB().materials('steel');
    el = HM24(mat,false);
    mesh = model.geometry.mesh;

    meshSize = size(mesh.nodes);

    left = find(mesh.nodes(1,:) == -9);
    bottom = find(mesh.nodes(2,:) == 0);
    constraint = unique([3*left, 3*left - 1,3*left - 2, 3*bottom - 1]);

    model.analysisType = 'Expl';
    U1 = sol(model,constraint,false);

    model.analysisType = 'Impl';
    U2 = sol(model,constraint,false);

    # h = plotMesh(mesh);
    # axis off
    #
    # set(h,'edgecolor','none');
    # clim([0,40]);
    # R = StaticResult(mesh,el,U1(:,8));
    #     plotSolution(R.mesh,R.vonMisesStress,R.displacement, 'Scale', 100, 'PlotHandle', h);
    #     filename = sprintf('BigMass.png',i);
    #     print(filename);
    #     R = StaticResult(mesh,el,U2(:,8));
    #     plotSolution(R.mesh,R.vonMisesStress,R.displacement, 'Scale', 100, 'PlotHandle', h);
    #     filename = sprintf('SmallMass.png',i);
    #     print(filename);
    small = Newmark;
    big = Central;

    omega = mat.waveSpeed / 18;
    T = 1 / omega

    Kurant = 0.56
    # dt = Kurant / mat.waveSpeed
    dt = 0.5
    count = 3.25 * T/dt

    small.setParam(dt);
    big.setParam(dt);
    [K,M] = el.assemble(model.geometry);

    smallNodes = 1:408;%find(abs(mesh.nodes(1,:)) <= 7);
    bigNodes = [151:204,355:548];%find(abs(mesh.nodes(1,:)) >= 6);

    smallIdx = node2ind(meshSize,[1,2,3],smallNodes);
    bigIdx = node2ind(meshSize,[1,2,3],bigNodes);

    small.K = K(smallIdx,smallIdx);
    small.M = M(smallIdx,smallIdx);

    big.K = K(bigIdx,bigIdx);
    big.M = M(bigIdx,bigIdx);

    Move = find(abs(mesh.nodes(1,:) + mesh.nodes(2,:)) + abs(mesh.nodes(1,:) - mesh.nodes(2,:)) == 14);
    Force = find(abs(mesh.nodes(1,:) + mesh.nodes(2,:)) + abs(mesh.nodes(1,:) - mesh.nodes(2,:)) == 12);

    smallMove = node2ind(meshSize,[1,2,3],find(ismember(smallNodes,Move)));
    bigMove = node2ind(meshSize,[1,2,3],find(ismember(bigNodes,Move)));

    smallForce = node2ind(meshSize,[1,2,3],find(ismember(smallNodes,Force)));
    bigForce = node2ind(meshSize,[1,2,3],find(ismember(bigNodes,Force)));

    bigLeft = node2ind(meshSize,[1,2,3],find(ismember(bigNodes,left)));

    bigBottom = node2ind(meshSize,2,find(ismember(bigNodes,bottom)));
    smallBottom = node2ind(meshSize,2,find(ismember(smallNodes,bottom)));

    small.constrain(smallBottom,smallMove);
    big.constrain([bigBottom;bigLeft],[]);

    # for k = 1:10
    big.t = 0;
    A0 = zeros(size(big.K,1),1);
    U0 = zeros(size(A0));
    V0 = zeros(size(A0));
    Bstate = big.IC(U0,V0,A0);

    A0 = zeros(size(small.K,1),1);
    U0 = zeros(size(A0));
    V0 = zeros(size(A0));
    Sstate = small.IC(U0,V0,A0);

    Bforce = zeros(size(big.K,1),1);
    Sforce = zeros(size(small.K,1),1);
    U = zeros(numel(model.load),13);
    j = 1;
    dt = T/4;
    t = dt * (1:50);
    # tic
    # for i = 1:count
    #     mod = -sin(2 * pi * omega * big.t);
    #     Bforce = mod * model.load(bigIdx);
    #     Bstate = big.step(Bstate,Bforce);
    #
    #     Sforce(smallMove) = Bstate(bigMove,1);
    #     if any(Sforce)
    #         Sstate = small.step(Sstate,Sforce);
    #     end
    #     # any(Sstate(smallMove,1) - Bstate(bigMove,1))
    #     Bstate(bigForce,1) = Sstate(smallForce,1);
    #
    #     if small.t >= t(j)
    #         U(bigIdx,j) = Bstate(:,1);
    #         U(smallIdx,j) = Sstate(:,1);
    #         t(j) = big.t;
    #         j +=1;
    #     end
    # end
    # U(bigIdx,j) = Bstate(:,1);
    # U(smallIdx,j) = Sstate(:,1);
    # t(j) = big.t;
    # toc
    # time(k) = toc;
    # end
    # disp(sum(time)/numel(time));
    h = plotMesh(mesh);
    axis off
    clim([0,40]);
    # clabel("MPa");
    set(h,'edgecolor','none');
    # for i = 1:size(U,2)
    #     title(sprintf('%.2fT',t(i)/T))
    #     R = StaticResult(mesh,el,U(:,i));
    #     plotSolution(R.mesh,R.vonMisesStress,R.displacement, 'Scale', 100, 'PlotHandle', h);
    #     filename = sprintf('mixed%d.png',i);
    #     print(filename);
    #     drawnow;
    #     # pause(0.3);
    # end
    # for i = 1:size(U,2)
    #     title(sprintf('%.2fT',t(i)/T))
    #     R = StaticResult(mesh,el,U1(:,i));
    #     plotSolution(R.mesh,R.vonMisesStress,R.displacement, 'Scale', 100, 'PlotHandle', h);
    #     filename = sprintf('expl%d.png',i);
    #     print(filename);
    #     drawnow;
    #     # pause(0.3);
    # end
    for i = 1:size(U,2)
        title(sprintf('%.2fT',t(i)/T))
        R = StaticResult(mesh,el,U2(:,i));
        plotSolution(R.mesh,R.vonMisesStress,R.displacement, 'Scale', 100, 'PlotHandle', h);
        # filename = sprintf('impl%d.png',i);
        # print(filename);
        drawnow;
        # pause(0.3);
    end

    # figure
    #
    # xlim([0,185]);
    # ylim([0,35]);
    # xlabel('deg');
    # ylabel('MPa');
    #
    # for i = 1:size(U,2)
    #
    #     R = StaticResult(mesh,el,U(:,i));
    #     R1 = StaticResult(mesh,el,U1(:,i));
    #     R2 = StaticResult(mesh,el,U2(:,i));
    #     filename = sprintf('circle%d.png',i);
    #     plot((24:-1:0)*180/24,R2.vonMisesStress(1:25));
    #     title(sprintf('%.2fT',t(i)/T))
    #     legend('mix','exp','imp')
    #     hold off
    #     drawnow;
    #     print(filename);
    #     cla

        # pause(0.3);
    # end
    # R = StaticResult(mesh,el,U);
end
