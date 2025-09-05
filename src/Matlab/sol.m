function result = sol(fem, constraint)
    mat = MaterialDB().materials('steel');
    el = HM24(mat,false);
    mesh = fem.geometry.mesh;

%         s = Newmark;
%         T = 2 * 18 / mat.waveSpeed
%         if isa(s,'Central')
%             Kurant = 0.12
%             dt = Kurant * 0.1308 / mat.waveSpeed;
%         else
%             dt = T / 100;
%             Kurant = mat.waveSpeed * dt / 0.1308
%         end
%         omega = 1/T;
%         omega *= 1;
%         count = 3.25/omega/dt
%
%         s.setParam(dt);
%
%         [K,M] = el.assemble(fem.geometry);
%         idx = [1:274];
%         smallIdx = sub2ind([3, fem.geometry.numVertices], repmat(1:2,1,numel(idx)), repelem(idx,2));
%         s.K = K(smallIdx,smallIdx);
%         s.M = M(smallIdx,smallIdx);
%
%         constraint = 205:214;
%         left = sub2ind([2, fem.geometry.numVertices], repmat(1:2,1,numel(constraint)), repelem(constraint,2));
%         constraint = [1:25:176, 25:25:175, 214, 224, 204,264, 274 ];
%         bottom = sub2ind([2, fem.geometry.numVertices], repmat(2,1,numel(constraint)), constraint);
%         s.constrain([left, bottom],[]);
%         A0 = zeros(size(s.K,1),1);
%         U0 = zeros(size(A0));
%         V0 = zeros(size(A0));
%         state = s.IC(U0,V0,A0);
%
%         size(fem.load)
%         load = fem.load([1,2],1:274)(:);
%         disp(count * dt);
%         h = plotMesh(fem.geometry.mesh);
%         clim([0 50]);
%         set(h, 'edgecolor','none');
%
%         vertices = get(h,'vertices');
%         tic
%         for i = 1:count
%             mod = sin(2 * pi * omega * s.t);
%             state = s.step(state,mod*load(:));
%             res = reshape(state(:,1),2,[]);
%             res(end+1,:) = zeros(1,size(res,2));
%             res = repmat(res,1,2);
%             R = StaticResult(mesh,el,res(:));
%             plotSolution(R.mesh,R.vonMisesStress,R.displacement, 'Scale', 100, 'PlotHandle', h);
%             drawnow;
%         end
%         toc
%         res = reshape(state(:,1),2,[]);
%         res(end+1,:) = zeros(1,size(res,2));
%         res = repmat(res,1,2);
%         R = StaticResult(mesh,el,res(:));
%
%         plotSolution(R.mesh,R.vonMisesStress,R.displacement);

    if strcmp(fem.analysisType, 'static')
        s = Static;

        s.assemble(el, fem.geometry);
        K = s.K;
        s.constrain(constraint,[]);

        U = s.solve(fem.load(:));
        R = StaticResult(mesh,el,U);
        m = reshape(fem.load(:) - K*U,3,[]);

%         plotSolution(R.mesh,R.vonMisesStress,R.displacement);
        plotSolution(R.mesh,'FlowData',m');
%         clim([0 18]);
    elseif strcmp(fem.analysisType, 'dynamic')
        small = Newmark;
        big = Central;

        T = 2 * 18 / mat.waveSpeed

        Kurant = 0.1
        dt = Kurant / mat.waveSpeed;
        omega = 1/T;
        omega *= 1;
        count = 3.25/omega/dt

        small.setParam(dt);
        big.setParam(dt);
        [K,M] = el.assemble(fem.geometry);

        K(constraint,:) = 0;
        K(:,constraint) = 0;
        K(sub2ind(size(K),constraint,constraint)) = 1;

        M(constraint,:) = 0;
        M(:,constraint) = 0;
        M(sub2ind(size(M),constraint,constraint)) = 1;

        smallNodes = unique(mesh.hexas(:,[1:170,189:216]));
        bigNodes = unique(mesh.hexas(:,[145:150,163:190,215:234]));
        mixedNodes = unique(mesh.hexas(:,[145:150,163:170,189,190,215,216]));

        smallIdx = [3*smallNodes - 2; 3*smallNodes - 1; 3*smallNodes];
        bigIdx = [3*bigNodes - 2; 3*bigNodes - 1; 3*bigNodes];
        mixedIdx = [3*mixedNodes - 2;3*mixedNodes - 1;3*mixedNodes];

        small.K = K;
        small.K(mixedIdx,:) = 0;
        small.K(sub2ind(size(K),mixedIdx,mixedIdx)) = 1;

        small.M = M;
%         small.M(mixedIdx,:) = 0;
%         small.M(sub2ind(size(M),mixedIdx,mixedIdx)) = 1;

        small.K = small.K(smallIdx,smallIdx);
        small.M = small.M(smallIdx,smallIdx);
        small.constrain([],[]);

        big.K = K(bigIdx,bigIdx);
        big.M = M(bigIdx,bigIdx);
        big.constrain([],[]);

        K = K(mixedIdx,mixedIdx);
        M = M(mixedIdx,mixedIdx);
        IBig = find(ismember(bigIdx,mixedIdx));
        Ismall = find(ismember(smallIdx,mixedIdx));

        A0 = zeros(numel(bigIdx),1);
        U0 = zeros(size(A0));
        V0 = zeros(size(A0));
        Bstate = big.IC(U0,V0,A0);

        A0 = zeros(numel(smallIdx),1);
        U0 = zeros(size(A0));
        V0 = zeros(size(A0));
        Sstate = small.IC(U0,V0,A0);

        Bforce = zeros(numel(bigIdx),1);
        Sforce = zeros(numel(smallIdx),1);
        U = zeros(numel(fem.load),1);

        h = plotMesh(fem.geometry.mesh);
        tic
        for i = 1:count
            moved = Bstate(IBig,1);
            Sforce(Ismall) = moved;
            Sstate = small.step(Sstate,Sforce);

            mod = sin(2 * pi * omega * small.t)
            Bforce = mod * fem.load(bigIdx);
            Bforce(IBig) += M*Sstate(Ismall,3) + K*Sstate(Ismall,1);
            Bstate = big.step(Bstate,Bforce);

            U(bigIdx) = Bstate(:,1);
            U(smallIdx) = Sstate(:,1);
            R = StaticResult(mesh,el,U);
            plotSolution(R.mesh,R.vonMisesStress,R.displacement, 'Scale', 100, 'PlotHandle', h);
            drawnow;
        end
        toc

%         R = StaticResult(mesh,el,U);
    else
        s = Newmark;
%         s = Central;

        T = 2 * 18 / mat.waveSpeed
        if isa(s,'Central')
            Kurant = 0.12
            dt = Kurant * 0.1308 / mat.waveSpeed;
        else
            dt = T / 100;
            Kurant = mat.waveSpeed * dt / 0.1308
        end
        omega = 1/T;
        omega *= 1;
        count = 3.25/omega/dt

        s.setParam(dt);

        s.assemble(el, fem.geometry);
        K = s.K;
        M = s.M;
        s.constrain(constraint,[]);

%         A0 = s.M \ fem.load(:);
        A0 = zeros(size(fem.load(:)));
        U0 = zeros(size(A0));
        V0 = zeros(size(A0));
        state = s.IC(U0,V0,A0);

        disp(count * dt);
        h = plotMesh(fem.geometry.mesh);
%         clim([0 50]);
%         set(h, 'edgecolor','none');

%         vertices = get(h,'vertices');
        tic
        for i = 1:count
            mod = sin(2 * pi * omega * s.t);
            state = s.step(state,mod*fem.load(:));
            m = reshape(mod*fem.load(:) - K*state(:,1) - M*state(:,3),3,[]);
            plotSolution(mesh,'FlowData',m','PlotHandle',h);
%             R = StaticResult(mesh,el,state(:,1));
%             plotSolution(R.mesh,R.vonMisesStress,R.displacement, 'Scale', 100, 'PlotHandle', h);
            drawnow;
        end
        toc
        R = StaticResult(mesh,el,state(:,1));

%         plotSolution(R.mesh,R.vonMisesStress,R.displacement);
    end
    result = R;
end

% function write
