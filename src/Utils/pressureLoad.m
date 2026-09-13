function F = pressureLoad(coords, value, normal)
    % if isa(grid,'Grid3D')
    %     % faces = grid.quads;
    %     dim = 3;
    % elseif isa(grid,'Grid2D')
    %     % faces = grid.generateEdge();
    %     dim = 2;
    % else
    %     error('incorrect grid type');
    % end
    % if isa(faceSelector,'function_handle')
    %     selected = false(1,numFaces);
    %     for i=1:numFaces
    %         coords = grid.nodes(1:dim,faces(:,i));
    %         selected = faceSelector(coords);
    %     end
    % elseif islogical(faceSelector) || isnumeric(faceSelector)
    %     selected = logical(faceSelector(:)');
    % else
    %     error('incorrect faceSelector type');
    % end
    % for i = find(selected)

    numNodes = size(coords,2);
    if numNodes == 4
        d1 = coords(:,3) - coords(:,1); % Diagonal 1
        d2 = coords(:,4) - coords(:,2); % Diagonal 2
        N = 0.5 * (cross(d1,d2));
    
        dS = norm(N);
    elseif numNodes == 2
        %TODO
    end

    if dS > 0
        if nargin == 2
            normal = N/dS;
        end
    else
        error("Zero area");
    end
    
    F = repmat(value * dS * normal / numNodes,1,numNodes);
end