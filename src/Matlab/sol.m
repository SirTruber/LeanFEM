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
        s.constrain(constraint,[]);

        U = s.solve(fem.load(:));
        R = StaticResult(mesh,el,U);
        plotSolution(R.mesh,R.vonMisesStress,R.displacement);
        clim([0 18]);
%     elseif strcmp(fem.analysisType, 'dynamic')
%         small = Newmark;
%         big = Central;
%
%         T = 2 * 18 / mat.waveSpeed
%
%         Kurant = 0.8
%             dt = Kurant / mat.waveSpeed;
% %         else
% %             dt = T / 100;
% %             Kurant = mat.waveSpeed * dt / 0.1308
% %         end
%
%         small.setParam(dt);
%         big.setParam(dt);
%         [K,M] = el.assemble(fem.geometry);
%         idx = [1:204,275:478];
%         smallIdx = sub2ind([3, fem.geometry.numVertices], repmat(1:3,1,numel(idx)), repelem(idx,3));
%         small.K = K(smallIdx,smallIdx);
%         small.M = M(smallIdx,smallIdx);
%
%         idx = [151:274,425:548];
%         bigIdx = sub2ind([3, fem.geometry.numVertices], repmat(1:3,1,numel(idx)), repelem(idx,3));
%         big.K = K(bigIdx,bigIdx);
%         big.M = M(bigIdx,bigIdx);
%         big.constrain(sub2ind([2, fem.geometry.numVertices], repmat(1:2,1,numel(constraint)), repelem(constraint,2)),[]);
%         moved = [151:204];
%         small.constrain([],sub2ind([2, fem.geometry.numVertices], repmat(1:2,1,numel(moved)), repelem(moved,2)));
%
%         state = zeros(size())
%         R = 'd';
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
        s.constrain(constraint,[]);

%         A0 = s.M \ fem.load(:);
        A0 = zeros(size(fem.load(:)));
        U0 = zeros(size(A0));
        V0 = zeros(size(A0));
        state = s.IC(U0,V0,A0);

        disp(count * dt);
%         h = plotMesh(fem.geometry.mesh);
%         clim([0 50]);
%         set(h, 'edgecolor','none');

%         vertices = get(h,'vertices');
        tic
        for i = 1:count
            mod = sin(2 * pi * omega * s.t);
            state = s.step(state,mod*fem.load(:));
%             R = StaticResult(mesh,el,state(:,1));
%             plotSolution(R.mesh,R.vonMisesStress,R.displacement, 'Scale', 100, 'PlotHandle', h);
%             drawnow;
        end
        toc
        R = StaticResult(mesh,el,state(:,1));

        plotSolution(R.mesh,R.vonMisesStress,R.displacement);
    end
    result = R;
end

% function write
