function h = plotMesh(varargin)
    p =  inputParser;

    p.addRequired('Mesh', @(x) validateattributes(x, {'Mesh'}, {}));
    p.addSwitch('NodeLabels');
    p.addSwitch('FaceLabels');
    p.addSwitch('ElementLabels');
    p.addParameter('NodeLabelColor', 'k', @(x) ischar(x) || isstring(x) || (isnumeric(x) && numel(x)==3));
    p.addParameter('FacesLabelColor', 'b', @(x) ischar(x) || isstring(x) || (isnumeric(x) && numel(x)==3));
    p.addParameter('ElementLabelColor', 'r', @(x) ischar(x) || isstring(x) || (isnumeric(x) && numel(x)==3));
    p.addParameter('FontSize', 10, @(x) isnumeric(x) && isscalar(x) && x > 0);

    p.parse(varargin{:});
    params = p.Results;

    mesh = params.Mesh;
    figHandle = figure('Units', 'pixels', 'Position', [150, 150, 1600, 1200]);

    faces = mesh.generateQuads();

    h = patch('Faces', faces', 'Vertices', mesh.nodes', 'FaceColor', 'c', 'EdgeColor', 'k','clipping','off');
    center = mesh.center;
    s = mesh.box;
    len = max(s(:,2) - s(:,1)) / 2;
    lim = [center - len, center + len];
    axis equal;
    xlim(lim(1,:));
    ylim(lim(2,:));
    zlim(lim(3,:));

    scale = 0.025 * len;
    if params.NodeLabels
        drawNodes(mesh,h,params,scale);
    end
    if params.FaceLabels
        drawFaces(mesh,h,params,scale)
    end
    if params.ElementLabels
        drawElements(mesh,h,params,scale);
    end
end

function drawNodes(mesh,patchHandle,params,scale)
    normals = getNormals(patchHandle,'vertexnormals');
    textPosition = mesh.nodes + scale * normals';
    x = textPosition(1,:);
    y = textPosition(2,:);
    z = textPosition(3,:);
    labels = arrayfun(@(i) sprintf('N%d',i),1:size(mesh.nodes,2), 'UniformOutput', false);
    text(x,y,z,labels,'color',params.NodeLabelColor, 'fontsize',params.FontSize,'horizontalalignment','center');
end

function drawFaces(mesh,patchHandle,params,scale)
    [faces, quadToHexas] = mesh.generateQuads();

    textBase = getFacesTextPosition(mesh,faces);
    normals = getNormals(patchHandle,'facenormals');

    textPosition = textBase + scale * normals';
    x = textPosition(1,:);
    y = textPosition(2,:);
    z = textPosition(3,:);

    labels = arrayfun(@(i) sprintf('F%d',i),1:size(faces,2), 'UniformOutput', false);
    text(x,y,z,labels,'color',params.FacesLabelColor, 'fontsize',params.FontSize,'horizontalalignment','center');
end

function drawElements(mesh,patchHandle,params,scale)
    [faces, quadToHexas] = mesh.generateQuads();

    textBase = getFacesTextPosition(mesh,faces)
    normals = getNormals(patchHandle,'facenormals');

    textPosition = textBase + scale * normals';
    x = textPosition(1,:);
    y = textPosition(2,:);
    z = textPosition(3,:);

    labels = arrayfun(@(i) sprintf('E%d',i),quadToHexas, 'UniformOutput', false);
    text(x,y,z,labels,'color',params.ElementLabelColor, 'fontsize',params.FontSize,'horizontalalignment','center');
end

function normals = getNormals(patchHandle,typeNormal)
    normals = get(patchHandle,typeNormal);
    if isempty(normals)
        light;
        lighting gouraud;
        lighting none;
        normals = get(patchHandle,typeNormal);
    end
end

function textBase = getFacesTextPosition(mesh,faces)
    textBase = mesh.nodes(:,faces);
    textBase = reshape(textBase,3,4,[]);
    textBase = mean(textBase,2);
    textBase = reshape(textBase,3,[]);
end
