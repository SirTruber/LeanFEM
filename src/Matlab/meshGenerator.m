function mesh = meshGenerator
    circleRadius = 2;
    numSubdivision = 48;
    height = 5;
    numRing = 9;
    numSubRegion = 14;

    geomProgressionCoeff = 1 + pi / (numSubdivision - 0.5 * pi);
    allRadius = circleRadius * geomProgressionCoeff.^[0:numSubRegion];
    allAngle = pi * [0:numSubdivision]/numSubdivision;

    nodes = cumputeNodes(allRadius,allAngle, 0.5,numRing + 1);

    hexas = circleHexas(numSubdivision, numRing + 1);
    mesh = Mesh(nodes,hexas);
    size(nodes)
    size(hexas)
end

function nodes = cumputeNodes(allRadius,allAngle, thick, numRing)
    x = allRadius(1:numRing + 1)' * cos(allAngle);
    y = allRadius(1:numRing + 1)' * sin(allAngle);

    x = x';
    y = y';

    radius = getRadius(allAngle,13);

    new_x = radius .* cos(allAngle);
    new_y = radius .* sin(allAngle);

    x = [x, new_x'];
    y = [y, new_y'];

    x = repelem(x(:),2);
    y = repelem(y(:),2);
    z = zeros(numel(x),1);
    z(2:2:end) = thick;

    nodes = [x,y,z]';
end

function hexas = circleHexas(numSubdivision,numRing)
    block = int32([1;2 * (numSubdivision + 1) + 1 ; 2 * (numSubdivision + 2) + 1;3]);
    block = [block;block + 1];
    ring = repmat(block,1,numSubdivision) + 2 * repelem(0:numSubdivision-1,8,1);
    sector = repmat(ring,1,numRing) + 2 * (numSubdivision + 1) * repelem(0:numRing-1,8,size(ring,2));
    hexas = sector;
end

function radius = getRadius(theta, beta)
    radius = real((cos(theta).^beta + sin(theta).^beta).^(-1/beta));
end
