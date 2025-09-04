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

        strainEl = el.computeGradient(mesh.points(i)) * U(:,nodes)(:);
        stressEl = el.elasticity * strainEl;

        strain(:,nodes) = strain(:,nodes) + strainEl(1:6) * VE(i);
        stress(:,nodes) = stress(:,nodes) + stressEl(1:6) * VE(i);
    end
    strain = strain ./ weight;
    stress = 1e5 * stress ./ weight; % В МПа
end
