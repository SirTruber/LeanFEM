function h = plotRes(res, varargin)
    h = plotMesh(res.mesh);

%     p =  inputParser;
%
%     p.addParameter('NodeLabels', false, @(x) islogical(x));
%     p.addParameter('ElementLabels', false, @(x) islogical(x));
%     p.addParameter('NodeLabelColor', 'k', @(x) ischar(x) || isstring(x) || (isnumeric(x) && numel(x)==3));
%     p.addParameter('ElementLabelColor', 'r', @(x) ischar(x) || isstring(x) || (isnumeric(x) && numel(x)==3));
%     p.addParameter('FontSize', 10, @(x) isnumeric(x) && isscalar(x) && x > 0);
%
%     p.parse(varargin{:});
%     params = p.Results;
        colormap turbo;
    colorbar;
    set(h,'facecolor','flat');
    faces = get(h,'faces');
    set(h, 'facevertexcdata', res.vonMisesStress);
    vertices = res.mesh.nodes' + [res.displacement.ux,res.displacement.uy,res.displacement.uz];
    set(h, 'vertices',vertices);
end
