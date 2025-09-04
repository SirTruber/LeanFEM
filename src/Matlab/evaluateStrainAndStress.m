function result = evaluateStrainAndStress(result)

    mesh = result.mesh;
    el = result.finiteElement;

    n = size(mesh.nodes,2);
    m = size(mesh.hexas,2);

    U = [result.displacement.ux,result.displacement.uy,result.displacement.uz]';
    U = reshape(U,3,n,[]);

    timeIdx = size(U,3); % ==1 - Static, >1 - Dynamic

    strainStress = zeros(12,n,timeIdx);

    [~, VE] = mesh.volume;
    weight = zeros(1,n);
    for i=1:m
        nodes = mesh.hexas(:,i);

        strainEl = result.finiteElement.computeGradient(mesh.points(i)) * reshape(U(:,nodes,:),24,[]);
        stressEl = result.finiteElement.elasticity * strainEl;
        strainStressEl = VE(i) * [strainEl(1:6,:);stressEl(1:6,:)];

        strainStress(:,nodes,:) += strainStressEl;
        weight(nodes) += VE(i);
    end

    strainStress = strainStress ./ weight;

    strainStress(7:end,:,:) *= 1e5; % В МПа

    S = reshape(strainStress(:), 12,[]);

    result.strain = struct('exx', reshape(S(1,:),n,[])...
                   ,'eyy', reshape(S(2,:),n,[])...
                   ,'ezz', reshape(S(3,:),n,[])...
                   ,'exy', reshape(S(4,:),n,[])...
                   ,'eyz', reshape(S(5,:),n,[])...
                   ,'exz', reshape(S(6,:),n,[]));

    result.stress = struct('sxx', reshape(S(7,:),n,[])...
                   ,'syy', reshape(S(8,:),n,[])...
                   ,'szz', reshape(S(9,:),n,[])...
                   ,'sxy', reshape(S(10,:),n,[])...
                   ,'syz', reshape(S(11,:),n,[])...
                   ,'sxz', reshape(S(12,:),n,[]));
end
