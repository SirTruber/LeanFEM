function data = loadFrom(filename)
    [~, ~, ext] = fileparts(filename);
    switch lower(ext)
        case '.4ekm'
            data = load4ekm(filename);
        case '.romanov'
            data = loadRomanov(filename);
        otherwise
            error('Unsupported format: %s', ext);
    end
end

function grid = loadRomanov(filename)
    grid = Grid3D;
    [~,grid.name,~] = fileparts(filename);
    fileID = fopen(filename,"r");

    nodes_size = sscanf(fgetl(fileID),'%d');
    hexas_size = sscanf(fgetl(fileID),'%d');

    grid.nodes = zeros(3, nodes_size, 'double');
    grid.hexas = zeros(8, hexas_size, 'int32');
    formatSpec = '%lf,%lf,%lf,%lf';
    for i = 1:nodes_size
        node = sscanf(fgetl(fileID),formatSpec)';
        grid.nodes(1:3,i) = node(1,2:end);
    end
    formatSpec = '%d,%d,%d,%d,%d,%d,%d,%d,%d';
    for i = 1:hexas_size
        hex = sscanf(fgetl(fileID),formatSpec)';
        grid.hexas(1:8,i) = hex(1,2:end);
    end
    fclose(fileID);
    grid.generateQuads();
end

function grid = load4ekm(filename)
    grid = Grid3D;
    [~,grid.name,~] = fileparts(filename);
    fileID = fopen(filename,"r");

    nodes_size = sscanf(fgetl(fileID),'%d');
    hexas_size = sscanf(fgetl(fileID),'%d');

    grid.nodes = zeros(3, nodes_size, 'double');
    grid.hexas = zeros(8, hexas_size, 'int32');
    for i = 1:nodes_size
        grid.nodes(1:3,i) = sscanf(fgetl(fileID),'%lf')';
    end
    for i = 1:hexas_size
        grid.hexas(1:8,i) = sscanf(fgetl(fileID),'%d')';
    end
    fclose(fileID);
    grid.generateQuads();
end
