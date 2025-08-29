function h = plotSolution(varargin)
    p = inputParser;

    p.addRequired('Res', @(x) validateattributes(x, {'StaticResult'}, {}));
    addParameter(p, 'ColorMapData', [], @(x) validateattributes(x, {'numeric'}, {'column'}));
%     addParameter(p, 'FlowData', [], @(x) validateattributes(x, {'numeric'}, {'2d', 'ncols', 3}));
    addParameter(p, 'Scale', 1.1, @(x) validateattributes(x, {'numeric'}, {'scalar'}));
    p.addSwitch('NodeLabels');
    p.addSwitch('ElementLabels');
    p.addParameter('NodeLabelColor', 'k', @(x) ischar(x) || isstring(x) || (isnumeric(x) && numel(x)==3));
    p.addParameter('ElementLabelColor', 'r', @(x) ischar(x) || isstring(x) || (isnumeric(x) && numel(x)==3));
    p.addParameter('FontSize', 10, @(x) isnumeric(x) && isscalar(x) && x > 0);

    parse(p, varargin{:});

    params = p.Results;

%     h = plotMesh(results.Res.mesh);
    mesh = params.Res.mesh;
    figHandle = figure('Units', 'pixels', 'Position', [150, 150, 1600, 1200]);

    faces = mesh.generateQuads();

    h = patch('Faces', faces', 'Vertices', mesh.nodes', 'FaceColor', 'c', 'EdgeColor', 'k','clipping','off');
    center = mesh.center;
    [l, r] = mesh.box;
    len = max(r - l) / 2;
    lim = [center - len, center + len];
    axis equal;
    xlim(lim(1,:));
    ylim(lim(2,:));
    zlim(lim(3,:));

    scale = 0.025 * len;
    if params.NodeLabels
        drawNodes(mesh,h,params,scale);
    end
    if params.ElementLabels
        drawElements(mesh,h,params,scale);
    end

    if ~isempty(params.ColorMapData)
        colormap turbo;
        colorbar;
        set(h,'facecolor','interp');
        set(h, 'facevertexcdata', params.ColorMapData);
    end
    displacement = params.Res.displacement;
    set(h, 'vertices',mesh.nodes' + params.Scale * [displacement.ux,displacement.uy,displacement.uz]);
end

function drawNodes(mesh,patchHandle,params,scale)
    normals = get(patchHandle,'vertexnormals');
    if isempty(normals)
        light;
        lighting gouraud;
        lighting none;
        normals = get(patchHandle,'vertexnormals');
    end
    textPosition = mesh.nodes + scale * normals';
    x = textPosition(1,:);
    y = textPosition(2,:);
    z = textPosition(3,:);
    labels = arrayfun(@(i) sprintf('N%d',i),1:size(mesh.nodes,2), 'UniformOutput', false);
    text(x,y,z,labels,'color',params.NodeLabelColor, 'fontsize',params.FontSize);
end

function drawElements(mesh,patchHandle,params,scale)
    [faces, quadToHexas] = mesh.generateQuads();

    normals = get(patchHandle,'facenormals');
    if isempty(normals)
        light;
        lighting gouraud;
        lighting none;
        normals = get(patchHandle,'facenormals');
    end

    textBase = mesh.nodes(:,faces);
    textBase = reshape(textBase,3,4,[]);
    textBase = mean(textBase,2);
    textBase = reshape(textBase,3,[]);
    normals = get(patchHandle,'facenormals');

    textPosition = textBase + scale * normals';
    x = textPosition(1,:);
    y = textPosition(2,:);
    z = textPosition(3,:);

    labels = arrayfun(@(i) sprintf('E%d',i),quadToHexas, 'UniformOutput', false);
    text(x,y,z,labels,'color',params.ElementLabelColor, 'fontsize',params.FontSize);
end
