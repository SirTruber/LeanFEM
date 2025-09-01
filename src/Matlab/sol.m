function result = sol(fem, constraint)
    mat = MaterialDB().materials('steel');
    el = HM24(mat);
    if strcmp(fem.analysisType, 'static')

        q = fem.load(:);
        K = el.assemble(fem.geometry);
        mesh = fem.geometry.mesh;

        K(constraint,:) = 0;
        K(:,constraint) = 0;
        K(sub2ind(size(K),constraint,constraint)) = 1;

        q(constraint) = 0;

        U = K \ q;
        tmp = reshape(U,3,[]);
        result = StaticResult(mesh,el,U);
%         result.displacement = struct('ux',tmp(1,:)','uy',tmp(2,:)','uz',tmp(3,:)');
%
%         [strain,stress] = evaluateStrainStress(el, mesh, U);
%
%         result.stress = struct('sxx',stress(1,:)','syy',stress(2,:)','szz',stress(3,:)','sxy',stress(4,:)','syz',stress(5,:)','szx',stress(6,:)');
%         result.strain = struct('exx',strain(1,:)','eyy',strain(2,:)','ezz',strain(3,:)','exy',strain(4,:)','eyz',strain(5,:)','ezx',strain(6,:)');
%         result.vonMisesStress = evaluateVonMisesStress(stress);
%
%         result.mesh = mesh;
    end
end

function fixed = getFixedDOF(fem)

end

function [strain,stress] = evaluateStrainAndStress(el, mesh, U)
        n = size(mesh.nodes,2);
        m = size(mesh.hexas,2);

        strain = zeros(6,n);
        stress = zeros(6,n);

        [~, VE] = mesh.volume;
        weight = zeros(1,n);
        for i=1:m
            nodes = mesh.hexas(:,i)';

            weight(nodes) = weight(nodes) + VE(i);

            strainEl = el.computeGradient(mesh.points(i)) * U(NodesSub2ind(nodes));
            stressEl = el.elasticity * strainEl;

            strain(:,nodes) = strain(:,nodes) + strainEl(1:6) * VE(i);
            stress(:,nodes) = stress(:,nodes) + stressEl(1:6) * VE(i);
        end
        strain = strain ./ weight;
        stress = stress ./ weight;
end

function vonMises = evaluateVonMisesStress(stress)
    vonMises = sqrt(0.5 * ((stress(1,:) - stress(2,:)).^2 + (stress(2,:) - stress(3,:)).^2 + (stress(3,:) - stress(1,:)).^2 + 6 * (stress(4,:).^2 + stress(5,:).^2 + stress(6,:).^2)))';
end

function [VE, VN] = getWeightCoeff(mesh)
    [~, VE] = mesh.volume;
    VN = accumarray(mesh.hexas(:), repmat(VE, 8, 1)(:), [size(mesh.nodes,2), 1]) / 8;
    VE = VE';
end

function ind = NodesSub2ind(sub)
    ind = 3 * repelem(sub,1,3) - repmat([2,1,0],1,numel(sub));
end
