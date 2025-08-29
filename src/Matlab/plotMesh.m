function h = plotMesh(mesh, varargin)
    p =  inputParser;

    p.addParameter('NodeLabels', false, @(x) islogical(x));
    p.addParameter('ElementLabels', false, @(x) islogical(x));
    p.addParameter('NodeLabelColor', 'k', @(x) ischar(x) || isstring(x) || (isnumeric(x) && numel(x)==3));
    p.addParameter('ElementLabelColor', 'r', @(x) ischar(x) || isstring(x) || (isnumeric(x) && numel(x)==3));
    p.addParameter('FontSize', 10, @(x) isnumeric(x) && isscalar(x) && x > 0);

    p.parse(varargin{:});
    params = p.Results;

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

    if params.NodeLabels
        obj.drawNodes(h,params);
    end
    if params.ElementLabels
        obj.drawElements(h,params);
    end
end

function drawNodes(mesh,patchHandle,params)
    normals = getNormals(patchHandle);
    textPosition = mesh.nodes + 0.1 * normals';
    x = textPosition(1,:);
    y = textPosition(2,:);
    z = textPosition(3,:);
    labels = arrayfun(@(i) sprintf('N%d',i),1:size(mesh.nodes,2), 'UniformOutput', false);
    text(x,y,z,labels,'color',params.NodeLabelColor, 'fontsize',params.FontSize);
end

function drawElements(mesh,patchHandle,params)
    [faces, quadToHexas] = mesh.generateQuads();

    normals = getNormals(patchHandle);

    textBase = mesh.nodes(:,faces);
    textBase = reshape(textBase,3,4,[]);
    textBase = mean(textBase,2);
    textBase = reshape(textBase,3,[]);
    normals = get(patchHandle,'facenormals');

    textPosition = textBase + 0.1 * normals';
    x = textPosition(1,:);
    y = textPosition(2,:);
    z = textPosition(3,:);

    labels = arrayfun(@(i) sprintf('E%d',i),quadToHexas, 'UniformOutput', false);
    text(x,y,z,labels,'color',params.ElementLabelColor, 'fontsize',params.FontSize);
end

function normals = getNormals(patchHandle)
    normals = get(patchHandle,'facenormals');
    if isempty(normals)
        light;
        lighting gouraud;
        lighting none;
        normals = get(patchHandle,'facenormals');
    end
end
