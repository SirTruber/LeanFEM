function mesh = loadMesh(filename)
    fileID = fopen(filename,"r");
    if ~is_valid_file_id(fileID)
        error('file not found');
    end
    mesh = struct(); %TODO изменить, когда будет готов класс mesh
    [~, mesh.name, ext] = fileparts(filename);
    try
        switch lower(ext)
            case '.4ekm'
                [mesh.nodes, mesh.hexas] = parse4ekm(fileID);
%                 grid.generateQuads();
            case '.romanov'
                [mesh.nodes, mesh.hexas] = parseRomanov(fileID);
%                 mesh.generateQuads();
%             case '.msh'
%                 grid = loadGmsh(filename);
%             case '.vtk'
%                 grid = loadVTK(filename);
            otherwise
                error('Unsupported format: %s', ext);
        end
        validateGrid(mesh);
    catch err
        fclose(fileID);
        rethrow(err);
    end
    fclose(fileID);
end

function [nodes, hexas] = parse4ekm(fileID)
    headerSize = [2;1];
    nodesDim = 3;
    elementDim = 8;
    try
        header = parseDataBlock(fileID, headerSize(1), headerSize(2),'int');
        numberOfNodes = header(1);
        numberOfHexas = header(2);
    catch err
        error('%s header', err.message);
    end
    try
        nodes = parseDataBlock(fileID, numberOfNodes, nodesDim, 'double');
    catch err
        error('%s nodes', err.message);
    end
    try
        hexas = parseDataBlock(fileID, numberOfHexas, elementDim, 'int'); % Нет проверки, все ли узлы существуют, ответственность билдера
    catch err
        error('%s hexas', err.message);
    end
end

function [nodes, hexas] = parseRomanov(fileID)
    headerSize = [2;1];
    nodesDim = 4;
    elementDim = 9;

    try
        header = parseDataBlock(fileID, headerSize(1), headerSize(2),'int');
        numberOfNodes = header(1);
        numberOfHexas = header(2);
    catch err
        error('%s header', err.message);
    end
    try
        nodes = parseDataBlock(fileID, numberOfNodes, nodesDim, 'double')(:,2:end);
    catch err
        error('%s nodes', err.message);
    end
    try
        hexas = parseDataBlock(fileID, numberOfHexas, elementDim, 'int')(:,2:end); % Нет проверки, все ли узлы существуют, ответственность билдера
    catch err
        error('%s hexas', err.message);
    end
end

%!function filename = setupTestData(testData, format)
%! filename = [tempname(), format];
%! fileID = fopen(filename, 'w');
%! fprintf(fileID, testData);
%! fclose(fileID);
%!endfunction
%%
%!     #1.1 Некорректный дескриптор файла
%!error <file not found>
%! loadMesh('not_found.txt');
%%
%!test #1.2 Неизвестный формат файла
%! filename = setupTestData('test','.not_supported');
%!
%! fail("loadMesh(filename)","Unsupported format: .not_supported");
%!
%! delete(filename);
%!
%% Тесты 4ekm
%!test #2.1.Корректная загрузка файла
%!
%! testData = sprintf('8 \n1 \n0.000000   0.000000   0.000000\n0.250000   0.000000   0.000000 \n0.500000   0.000000   0.000000\n0.750000   0.000000   0.000000\n1.000000   0.000000   0.000000\n0.000000   0.250000   0.000000\n   0.250000   0.250000   0.000000\n0.500000   0.250000   0.000000\n 1      2      3      4     5     6     7    8 ');
%! filename = setupTestData(testData,'.4ekm');
%!
%! grid = loadMesh(filename);
%!
%! delete(filename);
%!
%! assert(isa(grid.nodes, 'double'));
%! assert(size(grid.nodes), [8, 3]);
%! assert(grid.nodes, [0 0 0; 0.25 0 0; 0.5 0 0; 0.75 0 0; 1 0 0; 0 0.25 0; 0.25 0.25 0; 0.5 0.25 0]);
%!
%! assert(isa(grid.hexas, 'int32'));
%! assert(size(grid.hexas), [1, 8]);
%! assert(grid.hexas, int32([1 2 3 4 5 6 7 8]));
%!
%%     #2.2.Несуществующий файл
%!error <file not found>
%! loadMesh('non_existent_file.4ekm');
%%
%!test #2.3.Пустой файл
%! filename = setupTestData('', '.4ekm');
%!
%! fail("loadMesh(filename)","unexpected EOF on line 1 of block header");
%!
%! delete(filename);
%!
%!test #2.4.Неполные данные узлов
%!
%! testData = sprintf('8 \n1 \n0.000000   0.000000 \n0.250000   0.000000   \n0.500000   0.000000 \n0.750000   0.000000 \n1.000000   0.000000   \n0.000000   0.250000 \n   0.250000   0.250000 \n0.500000   0.250000\n 1      2      3      4     5     6     7     8');
%! filename = setupTestData(testData,'.4ekm');
%!
%! fail("loadMesh(filename)","expected 3 numbers, but 2 is read on line 1 of block nodes");
%!
%! delete(filename);
%!
%!test #2.5.Неполные данные элементов
%!
%! testData = sprintf('8 \n2 \n0.000000   0.000000   0.000000\n0.250000   0.000000   0.000000 \n0.500000   0.000000   0.000000\n0.750000   0.000000   0.000000\n1.000000   0.000000   0.000000\n0.000000   0.250000   0.000000\n   0.250000   0.250000   0.000000\n0.500000   0.250000   0.000000\n 1      2      3      4     5     6     7     8');
%! filename = setupTestData(testData, '.4ekm');
%!
%! fail("loadMesh(filename)","unexpected EOF on line 2 of block hexas");
%!
%! delete(filename);
%!
%!xtest #2.6.Несуществующие узлы в элементах
%!
%! testData = sprintf('8 \n1 \n0.000000   0.000000   0.000000\n0.250000   0.000000   0.000000 \n0.500000   0.000000   0.000000\n0.750000   0.000000   0.000000\n1.000000   0.000000   0.000000\n0.000000   0.250000   0.000000\n   0.250000   0.250000   0.000000\n0.500000   0.250000   0.000000\n 11      12      13      14     5     6     7    11 ');
%! filename = setupTestData(testData,'.4ekm');
%!
%! fail("loadMesh(filename)","Non existed nodes with numbers [11 12 13 14] finding in elements 1");
%!
%! delete(filename);
%!
%% Тесты romanov
%!test #3.1.Корректная загрузка файла
%!
%! testData = sprintf('8 \n1 \n1 0.000000   0.000000   0.000000\n2 0.250000   0.000000   0.000000 \n3 0.500000   0.000000   0.000000\n4 0.750000   0.000000   0.000000\n5 1.000000   0.000000   0.000000\n6 0.000000   0.250000   0.000000\n7  0.250000   0.250000   0.000000\n8 0.500000   0.250000   0.000000\n1  1      2      3      4     5     6     7    8 ');
%! filename = setupTestData(testData,'.romanov');
%!
%! grid = loadMesh(filename);
%!
%! delete(filename);
%!
%! assert(isa(grid.nodes, 'double'));
%! assert(size(grid.nodes), [8, 3]);
%! assert(grid.nodes, [0 0 0; 0.25 0 0; 0.5 0 0; 0.75 0 0; 1 0 0; 0 0.25 0; 0.25 0.25 0; 0.5 0.25 0]);
%!
%! assert(isa(grid.hexas, 'int32'));
%! assert(size(grid.hexas), [1, 8]);
%! assert(grid.hexas, int32([1 2 3 4 5 6 7 8]));
%!
%%     #3.2.Несуществующий файл
%!error <file not found>
%! loadMesh('non_existent_file.romanov');
%%
%!test #3.3.Пустой файл
%! filename = setupTestData('', '.romanov');
%!
%! fail("loadMesh(filename)","unexpected EOF on line 1 of block header");
%!
%! delete(filename);
%!
%!test #3.4.Неполные данные узлов
%!
%! testData = sprintf('8 \n1 \n1 0.000000   0.000000 \n2 0.250000   0.000000   \n3 0.500000   0.000000 \n4 0.750000   0.000000 \n5 1.000000   0.000000   \n6 0.000000   0.250000 \n7   0.250000   0.250000 \n8 0.500000   0.250000\n1 1      2      3      4     5     6     7     8');
%! filename = setupTestData(testData,'.romanov');
%!
%! fail("loadMesh(filename)","expected 4 numbers, but 3 is read on line 1 of block nodes");
%!
%! delete(filename);
%!
%!test #3.5.Неполные данные элементов
%!
%! testData = sprintf('8 \n2 \n1 0.000000   0.000000   0.000000\n2 0.250000   0.000000   0.000000 \n3 0.500000   0.000000   0.000000\n4 0.750000   0.000000   0.000000\n5 1.000000   0.000000   0.000000\n6 0.000000   0.250000   0.000000\n7    0.250000   0.250000   0.000000\n8 0.500000   0.250000   0.000000\n 1 1      2      3      4     5     6     7     8');
%! filename = setupTestData(testData, '.romanov');
%!
%! fail("loadMesh(filename)","unexpected EOF on line 2 of block hexas");
%!
%! delete(filename);
%!
%!xtest #3.6.Несуществующие узлы в элементах
%!
%! testData = sprintf('8 \n1 \n1 0.000000   0.000000   0.000000\n2 0.250000   0.000000   0.000000 \n3 0.500000   0.000000   0.000000\n4 0.750000   0.000000   0.000000\n5 1.000000   0.000000   0.000000\n6 0.000000   0.250000   0.000000\n7    0.250000   0.250000   0.000000\n8 0.500000   0.250000   0.000000\n 1 11      12      13      14     5     6     7     11');
%! filename = setupTestData(testData,'.romanov');
%!
%! fail("loadMesh(filename)","Non existed nodes with numbers [11 12 13 14] finding in elements 1");
%!
%! delete(filename);
%!

% function grid = loadGmsh(filename)
%     grid = GridData;
%     [~,grid.name,~] = fileparts(filename);
%     % Открытие файла
%     fid = fopen(filename, 'r');
%     if fid == -1
%         error('Не удалось открыть файл: %s', filename);
%     end
% % Проверка версии формата
%     line = fgetl(fid);
%     if ~strcmp(line, '$MeshFormat')
%         error('Неверный формат файла: отсутствует $MeshFormat');
%     end
%
%     % Чтение версии формата
%     format_line = fgetl(fid);
%     version = sscanf(format_line, '%f', 1);
%     if version < 4.0 || version >= 5.0
%         error('Поддерживается только версия формата 4.1 (получена %.1f)', version);
%     end
%
%     % Пропуск конца секции
%     line = fgetl(fid);
%     if ~strcmp(line, '$EndMeshFormat')
%         error('Ожидался конец секции $MeshFormat');
%     end
%
%     % Поиск секции узлов и элементов
%     while ~feof(fid)
%         line = fgetl(fid);
%         if strcmp(line, '$Nodes')
%             grid.nodes = readNodes(fid);
%         end
%         if strcmp(line, '$Elements')
%             [grid.quads, grid.hexas] = readElements(fid);
%         end
%     end
%
%     fclose(fid);
% end
%
% %% Вспомогательные функции
% function nodes = readNodes(fid)
%     % Чтение количества сущностей
%     line = fgetl(fid);
%     numEntityBlocks = sscanf(line, '%d', 1);
%     totalNodes = sscanf(line, '%*d %d', 1);
%
%     % Инициализация массива узлов
%     nodes = zeros(totalNodes, 3);
%
%     % Чтение блоков узлов
%     for block = 1:numEntityBlocks
%         % Чтение заголовка блока
%         line = fgetl(fid);
%
%         header = sscanf(line, '%d %d %d %d');
%         numNodesInBlock = header(4);
%
%         % Чтение индексов узлов
%         nodeTags = fscanf(fid, '%d', numNodesInBlock);
%
%         % Чтение координат узлов
%         coords = fscanf(fid, '%f', [3, numNodesInBlock])';
%
%         % Сохранение узлов (индексы nodeTags могут быть несортированными)
%         for i = 1:numNodesInBlock
%             nodes(nodeTags(i), :) = coords(i, :);
%         end
%     end
%
% %     % Проверка конца секции
% %     line = fgetl(fid);
% %     if ~strcmp(line, '$EndNodes')
% %         error('Ожидался конец секции $Nodes');
% %     end
% end
%
% function [quads, hexas] = readElements(fid)
%     % Чтение секции элементов и извлечение только quads и hexas
%
%     % Инициализация
%     quads = [];
%     hexas = [];
%
%     % Чтение количества сущностей
%     line = fgetl(fid);
%     numEntityBlocks = sscanf(line, '%d', 1);
%     totalElements = sscanf(line, '%*d %d', 1);
%
%     % Чтение блоков элементов
%     for block = 1:numEntityBlocks
%         % Чтение заголовка блока
%         line = fgetl(fid);
%         header = sscanf(line, '%d %d %d %d', 4);
%         elementType = header(2);
%         numElementsInBlock = header(3);
%
%         % Чтение данных элементов в зависимости от типа
%         switch elementType
%             case 1 % Line (2-node)
%                 skip = 5;
%                 fscanf(fid, '%d', numElementsInBlock * skip);
%             case 2 % Triangle (3-node)
%                 skip = 6;
%                 fscanf(fid, '%d', numElementsInBlock * skip);
%             case 3 % Quad (4-node)
%                 data = fscanf(fid, '%d %d %d %d %d %d %d %d %d', [9, numElementsInBlock])';
%                 quads = [quads; data(:, 6:9)]; % Последние 4 числа - это узлы
%             case 4 % Tetrahedron (4-node)
%                 skip = 7;
%                 fscanf(fid, '%d', numElementsInBlock * skip);
%             case 5 % Hexahedron (8-node)
%                 data = fscanf(fid, '%d %d %d %d %d %d %d %d %d %d %d', [11, numElementsInBlock])';
%                 hexas = [hexas; data(:, 6:13)]; % Последние 8 чисел - это узлы
%             case 15 % Point (1-node)
%                 skip = 4;
%                 fscanf(fid, '%d', numElementsInBlock * skip);
%             otherwise
%                 error('Неизвестный тип элемента: %d', elementType);
%         end
%     end
%
% %     % Проверка конца секции
% %     line = fgetl(fid);
% %     if ~strcmp(line, '$EndElements')
% %         error('Ожидался конец секции $Elements');
% %     end
% end
