function [data,format] = loadFrom(filename)
    [~, ~, ext] = fileparts(filename);
    switch lower(ext)
        case '.4ekm'
            data = load4ekm(filename);
            format = 'grid';
        case '.msh'
            data = loadGmsh(filename);
            format = 'grid';
        case '.vtk'
            data = loadVTK(filename);
            format = 'grid';
        case '.romanov'
            data = loadRomanov(filename);
            format = 'grid';
        otherwise
            error('Unsupported format: %s', ext);
    end
end

function grid = loadRomanov(filename)
    grid = GridData;
    [~,grid.name,~] = fileparts(filename);
    fileID = fopen(filename,"r");

    nodes_size = sscanf(fgetl(fileID),'%d');
    hexas_size = sscanf(fgetl(fileID),'%d');

    grid.nodes = zeros(nodes_size ,3,'double');
    grid.hexas = zeros(hexas_size ,8,'int32');

    formatSpec = '%lf,%lf,%lf,%lf';
    for i = 1:nodes_size
        node = sscanf(fgetl(fileID),formatSpec)';
        grid.nodes(i,1:3) = node(1,2:end);
    end
    formatSpec = '%d,%d,%d,%d,%d,%d,%d,%d,%d';
    for i = 1:hexas_size
        hex = sscanf(fgetl(fileID),formatSpec)';
        grid.hexas(i,1:8) = hex(1,2:end);
    end
    fclose(fileID);
    grid.generateQuads();
end

function grid = load4ekm(filename)
    grid = GridData;
    [~,grid.name,~] = fileparts(filename);
    fileID = fopen(filename,"r");

    nodes_size = sscanf(fgetl(fileID),'%d');
    hexas_size = sscanf(fgetl(fileID),'%d');

    grid.nodes = zeros(nodes_size ,3,'double');
    grid.hexas = zeros(hexas_size ,8,'int32');
    for i = 1:nodes_size
        grid.nodes(i,1:3) = sscanf(fgetl(fileID),'%lf')';
    end
    for i = 1:hexas_size
        grid.hexas(i,1:8) = sscanf(fgetl(fileID),'%d')';
    end
    fclose(fileID);
    grid.generateQuads();
end

function grid = loadGmsh(filename)
    grid = GridData;
    [~,grid.name,~] = fileparts(filename);
    % Открытие файла
    fid = fopen(filename, 'r');
    if fid == -1
        error('Не удалось открыть файл: %s', filename);
    end
% Проверка версии формата
    line = fgetl(fid);
    if ~strcmp(line, '$MeshFormat')
        error('Неверный формат файла: отсутствует $MeshFormat');
    end

    % Чтение версии формата
    format_line = fgetl(fid);
    version = sscanf(format_line, '%f', 1);
    if version < 4.0 || version >= 5.0
        error('Поддерживается только версия формата 4.1 (получена %.1f)', version);
    end

    % Пропуск конца секции
    line = fgetl(fid);
    if ~strcmp(line, '$EndMeshFormat')
        error('Ожидался конец секции $MeshFormat');
    end

    % Поиск секции узлов и элементов
    while ~feof(fid)
        line = fgetl(fid);
        if strcmp(line, '$Nodes')
            grid.nodes = readNodes(fid);
        end
        if strcmp(line, '$Elements')
            [grid.quads, grid.hexas] = readElements(fid);
        end
    end

    fclose(fid);
end

%% Вспомогательные функции
function nodes = readNodes(fid)
    % Чтение количества сущностей
    line = fgetl(fid);
    numEntityBlocks = sscanf(line, '%d', 1);
    totalNodes = sscanf(line, '%*d %d', 1);

    % Инициализация массива узлов
    nodes = zeros(totalNodes, 3);

    % Чтение блоков узлов
    for block = 1:numEntityBlocks
        % Чтение заголовка блока
        line = fgetl(fid);

        header = sscanf(line, '%d %d %d %d');
        numNodesInBlock = header(4);

        % Чтение индексов узлов
        nodeTags = fscanf(fid, '%d', numNodesInBlock);

        % Чтение координат узлов
        coords = fscanf(fid, '%f', [3, numNodesInBlock])';

        % Сохранение узлов (индексы nodeTags могут быть несортированными)
        for i = 1:numNodesInBlock
            nodes(nodeTags(i), :) = coords(i, :);
        end
    end

%     % Проверка конца секции
%     line = fgetl(fid);
%     if ~strcmp(line, '$EndNodes')
%         error('Ожидался конец секции $Nodes');
%     end
end

function [quads, hexas] = readElements(fid)
    % Чтение секции элементов и извлечение только quads и hexas

    % Инициализация
    quads = [];
    hexas = [];

    % Чтение количества сущностей
    line = fgetl(fid);
    numEntityBlocks = sscanf(line, '%d', 1);
    totalElements = sscanf(line, '%*d %d', 1);

    % Чтение блоков элементов
    for block = 1:numEntityBlocks
        % Чтение заголовка блока
        line = fgetl(fid);
        header = sscanf(line, '%d %d %d %d', 4);
        elementType = header(2);
        numElementsInBlock = header(3);

        % Чтение данных элементов в зависимости от типа
        switch elementType
            case 1 % Line (2-node)
                skip = 5;
                fscanf(fid, '%d', numElementsInBlock * skip);
            case 2 % Triangle (3-node)
                skip = 6;
                fscanf(fid, '%d', numElementsInBlock * skip);
            case 3 % Quad (4-node)
                data = fscanf(fid, '%d %d %d %d %d %d %d %d %d', [9, numElementsInBlock])';
                quads = [quads; data(:, 6:9)]; % Последние 4 числа - это узлы
            case 4 % Tetrahedron (4-node)
                skip = 7;
                fscanf(fid, '%d', numElementsInBlock * skip);
            case 5 % Hexahedron (8-node)
                data = fscanf(fid, '%d %d %d %d %d %d %d %d %d %d %d', [11, numElementsInBlock])';
                hexas = [hexas; data(:, 6:13)]; % Последние 8 чисел - это узлы
            case 15 % Point (1-node)
                skip = 4;
                fscanf(fid, '%d', numElementsInBlock * skip);
            otherwise
                error('Неизвестный тип элемента: %d', elementType);
        end
    end

%     % Проверка конца секции
%     line = fgetl(fid);
%     if ~strcmp(line, '$EndElements')
%         error('Ожидался конец секции $Elements');
%     end
end
