function h = plotSolution(varargin)
    p = inputParser;

    p.addRequired('Mesh', @(x) validateattributes(x, {'Mesh'}, {}));
    p.addOptional('ColorMapData', [], @(x) validateattributes(x, {'numeric'}, {'column'}));
    p.addOptional('Displacement', [], @(x) validateattributes(x, {'struct'}, {}));
%     addParameter(p, 'FlowData', [], @(x) validateattributes(x, {'numeric'}, {'2d', 'ncols', 3}));
    addParameter(p, 'Scale', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));

    p.addSwitch('NodeLabels');
    p.addSwitch('FaceLabels');
    p.addSwitch('ElementLabels');
    p.addParameter('NodeLabelColor', 'k', @(x) ischar(x) || isstring(x) || (isnumeric(x) && numel(x)==3));
    p.addParameter('FacesLabelColor', 'b', @(x) ischar(x) || isstring(x) || (isnumeric(x) && numel(x)==3));
    p.addParameter('ElementLabelColor', 'r', @(x) ischar(x) || isstring(x) || (isnumeric(x) && numel(x)==3));
    p.addParameter('FontSize', 10, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('PlotHandle',[], @(x) isnumeric(x));

    parse(p, varargin{:});

    params = p.Results;

    h = 0;
    if isempty(params.PlotHandle)
        h = plotMesh(getMeshParams(params){:});
    else
        h = params.PlotHandle;
    end

    if ~isempty(params.ColorMapData)
        colormap cool;
        colorbar;
        set(h,'facecolor','interp');
        set(h, 'facevertexcdata', params.ColorMapData);
    end
    if ~isempty(params.Displacement)
        d = params.Displacement;
        if isempty(params.Scale)
            magnitude = max (sqrt(d.ux.^2 + d.uy.^2 + d.uz.^2));
            if magnitude < 1e-6
                scale = 1;
            else
                box = params.Mesh.box;
                len = max(box(:,2) - box(:,1));
                scale = 0.1 * len / magnitude
            end
        else
            scale = params.Scale;
        end
        vertices = params.Mesh.nodes' + scale * [d.ux, d.uy, d.uz];
        set(h, 'vertices', vertices);
    end
end

function meshParams = getMeshParams(p)
    meshParams = {p.Mesh,'NodeLabelColor',p.NodeLabelColor,'FacesLabelColor',p.FacesLabelColor,'ElementLabelColor',p.ElementLabelColor,'FontSize',p.FontSize};
    if p.NodeLabels
        meshParams(end+1) = {'NodeLabels'};
    end
    if p.FaceLabels
        meshParams(end+1) = {'FaceLabels'};
    end
    if p.ElementLabels
        meshParams(end+1) = {'ElementLabels'};
    end
end
