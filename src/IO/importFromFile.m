function data = importFromFile(filename)
    fileID = fopen(filename,"r");
    if ~is_valid_file_id(fileID)
        error('file not found');
    end
    data = struct(); %TODO изменить, когда будет готов класс mesh
    [~, data.name, ext] = fileparts(filename);
    try
        switch lower(ext)
            case '.4ekm'
                [data.nodes, data.hexas] = parse4ekm(fileID);
%                 data.generateQuads();
            case '.romanov'
                [data.nodes, data.hexas] = parseRomanov(fileID);
%                 mesh.generateQuads();
%             case '.msh'
%                 grid = loadGmsh(filename);
%             case '.vtk'
%                 grid = loadVTK(filename);
            otherwise
                error('Unsupported format: %s', ext);
        end
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
        nodes = parseDataBlock(fileID, numberOfNodes, 1 + nodesDim, 'double')(:,2:end);
    catch err
        error('%s nodes', err.message);
    end
    try
        hexas = parseDataBlock(fileID, numberOfHexas, 1 + elementDim, 'int')(:,2:end); % Нет проверки, все ли узлы существуют, ответственность билдера
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
%% importFromFile
%!     #1 Некорректный дескриптор файла
%!error <file not found>
%! importFromFile('not_found.txt');
%%
%!test #2 Неизвестный формат файла
%! filename = setupTestData('test','.not_supported');
%!
%! fail("importFromFile(filename)","Unsupported format: .not_supported");
%!
%! delete(filename);
%!
%% Тесты 4ekm
%!test #3.Корректная загрузка файла
%!
%! testData = sprintf('8 \n1 \n0.000000   0.000000   0.000000\n0.250000   0.000000   0.000000 \n0.500000   0.000000   0.000000\n0.750000   0.000000   0.000000\n1.000000   0.000000   0.000000\n0.000000   0.250000   0.000000\n   0.250000   0.250000   0.000000\n0.500000   0.250000   0.000000\n 1      2      3      4     5     6     7    8 ');
%! filename = setupTestData(testData,'.4ekm');
%!
%! grid = importFromFile(filename);
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
%%     #4.Несуществующий файл
%!error <file not found>
%! importFromFile('non_existent_file.4ekm');
%%
%!test #5.Пустой файл
%! filename = setupTestData('', '.4ekm');
%!
%! fail("importFromFile(filename)","unexpected EOF on line 1 of block header");
%!
%! delete(filename);
%!
%!test #6.Неполные данные узлов
%!
%! testData = sprintf('8 \n1 \n0.000000   0.000000 \n0.250000   0.000000   \n0.500000   0.000000 \n0.750000   0.000000 \n1.000000   0.000000   \n0.000000   0.250000 \n   0.250000   0.250000 \n0.500000   0.250000\n 1      2      3      4     5     6     7     8');
%! filename = setupTestData(testData,'.4ekm');
%!
%! fail("importFromFile(filename)","expected 3 numbers, but 2 is read on line 1 of block nodes");
%!
%! delete(filename);
%!
%!test #7.Неполные данные элементов
%!
%! testData = sprintf('8 \n2 \n0.000000   0.000000   0.000000\n0.250000   0.000000   0.000000 \n0.500000   0.000000   0.000000\n0.750000   0.000000   0.000000\n1.000000   0.000000   0.000000\n0.000000   0.250000   0.000000\n   0.250000   0.250000   0.000000\n0.500000   0.250000   0.000000\n 1      2      3      4     5     6     7     8');
%! filename = setupTestData(testData, '.4ekm');
%!
%! fail("importFromFile(filename)","unexpected EOF on line 2 of block hexas");
%!
%! delete(filename);
%!
%% Тесты romanov
%!test #9.Корректная загрузка файла
%!
%! testData = sprintf('8 \n1 \n1 0.000000   0.000000   0.000000\n2 0.250000   0.000000   0.000000 \n3 0.500000   0.000000   0.000000\n4 0.750000   0.000000   0.000000\n5 1.000000   0.000000   0.000000\n6 0.000000   0.250000   0.000000\n7  0.250000   0.250000   0.000000\n8 0.500000   0.250000   0.000000\n1  1      2      3      4     5     6     7    8 ');
%! filename = setupTestData(testData,'.romanov');
%!
%! grid = importFromFile(filename);
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
%%     #10.Несуществующий файл
%!error <file not found>
%! importFromFile('non_existent_file.romanov');
%%
%!test #11.Пустой файл
%! filename = setupTestData('', '.romanov');
%!
%! fail("importFromFile(filename)","unexpected EOF on line 1 of block header");
%!
%! delete(filename);
%!
%!test #12.Неполные данные узлов
%!
%! testData = sprintf('8 \n1 \n1 0.000000   0.000000 \n2 0.250000   0.000000   \n3 0.500000   0.000000 \n4 0.750000   0.000000 \n5 1.000000   0.000000   \n6 0.000000   0.250000 \n7   0.250000   0.250000 \n8 0.500000   0.250000\n1 1      2      3      4     5     6     7     8');
%! filename = setupTestData(testData,'.romanov');
%!
%! fail("importFromFile(filename)","expected 4 numbers, but 3 is read on line 1 of block nodes");
%!
%! delete(filename);
%!
%!test #13.Неполные данные элементов
%!
%! testData = sprintf('8 \n2 \n1 0.000000   0.000000   0.000000\n2 0.250000   0.000000   0.000000 \n3 0.500000   0.000000   0.000000\n4 0.750000   0.000000   0.000000\n5 1.000000   0.000000   0.000000\n6 0.000000   0.250000   0.000000\n7    0.250000   0.250000   0.000000\n8 0.500000   0.250000   0.000000\n 1 1      2      3      4     5     6     7     8');
%! filename = setupTestData(testData, '.romanov');
%!
%! fail("importFromFile(filename)","unexpected EOF on line 2 of block hexas");
%!
%! delete(filename);
%!
