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

function data = parseDataBlock(fileID, rows, columns, type)
    validateParseAttribute(fileID, rows, columns, type);

    [dataType, spec] = getTypeParameters(type);

    data = zeros(rows, columns, dataType);
    for i = 1:rows
        line = fgetl(fileID);
        if ~ischar(line)
            error('unexpected EOF on line %d of block',i);
        end
        try
            data(i,:) = parseLine(line, columns, spec);
        catch err
            error('%s on line %d of block', err.message, i);
        end
    end
end

function values = parseLine(line, length, spec)
    [values, num, err, index] = sscanf(line,spec,[1, length]);

    if ~isempty(err)
        errorFromSscanf(index,line,spec);
    end

    if num ~= length
        error('expected %d numbers, but %d is read', length, num);
    end
end

function validateParseAttribute(fileID, rows, columns, type)
    if ~is_valid_file_id(fileID)
        error('invalid file descriptor of block');
    end
    validateattributes(rows, {'numeric'}, {'scalar', 'integer', 'positive'});
    validateattributes(columns, {'numeric'}, {'scalar', 'integer', 'positive'});
    if ~isTypeSupported(type)
        error('unsupported type: %s of block',type);
    end
end

function typeSpecs = getTypeSpecification()
    typeSpecs = struct(...
        'int',    struct('dataType', 'int32',  'spec', '%d'), ...
        'float',  struct('dataType', 'single', 'spec', '%f'), ...
        'double', struct('dataType', 'double', 'spec', '%lf'), ...
        'char',   struct('dataType', 'char',   'spec', '%c') ...
    );
end

function isValid = isTypeSupported(type)
    isValid = isfield(getTypeSpecification, lower(type));
end

function [dataType, spec] = getTypeParameters(type)
    specStruct = getTypeSpecification.(lower(type));
    dataType = specStruct.dataType;
    spec = specStruct.spec;
end

function errorFromSscanf(index, line, spec)
    if isempty(line)
        error('empty line');
    end

    if index <= numel(line);
        error('invalid symbol: %c', line(index));
    end
end

%!function filename = setupTestData(testData, format)
%! filename = [tempname(), format];
%! fileID = fopen(filename, 'w');
%! fprintf(fileID, testData);
%! fclose(fileID);
%!endfunction
%%
%% parseLine
%%
%!test #1.1.Корректные целые числа
%! res = parseLine('1 2 3',3,'%d');
%! assert(res,[1 2 3]);
%!
%!test #1.2.Отрицательные целые числа
%! res = parseLine('-1 -2',2,'%d');
%! assert(res,[-1 -2]);
%!
%!test #1.3.Корректные числа с плавающей запятой
%! res = parseLine("1.0 2.5 -3.7", 3, '%f');
%! assert(res, [1.0, 2.5, -3.7], 1e-6);
%!
%!test #1.4.Числа в экспоненциальной записи
%! res = parseLine("1e2 2.5e-1 3.7E+3", 3, '%f');
%! assert(res, [100, 0.25, 3700], 1e-6);
%!
%!test #1.5.Смешанные числа
%! res = parseLine("1 2.0 3", 3, '%f');
%! assert(res, [1.0, 2.0, 3.0], 1e-6);
%!
%!     #1.6.Недостаточное колличество чисел
%!error <expected 3 numbers, but 2 is read> parseLine("1 2", 3, '%f');
%!
%!test #1.7.Лишние числа игнорируются
%! res = parseLine("1 2 3 4", 3, '%d');
%! assert(res, [1, 2, 3]);
%!
%!     #1.8.Некорректные символы в начале
%!error <invalid symbol: a> parseLine("a", 1, '%d');
%!
%!     #1.9.Некорректные символы в середине
%!error <invalid symbol: a> parseLine("1 a 3", 3, '%d');
%!
%!     #1.10.Пустая строка
%!error <empty line> parseLine("", 1, '%d');
%!
%!test #1.11.Строка с пробелами
%! res = parseLine("   1  2.5  -3   ", 3, '%f');
%! assert(res, [1.0, 2.5, -3.0], 1e-6);
%!
%!test #1.12.Разные разделители
%! res = parseLine("1\t2.5\t3", 3, '%f');
%! assert(res, [1.0, 2.5, 3.0], 1e-6);
%%
%% parseDataBlock
%%
%!test #2.1.Корректное чтение блока целых чисел
%! testData = sprintf('1 \n2\n 3');
%! filename = setupTestData(testData);
%!
%! fileID = fopen(filename, 'r');
%! data = parseDataBlock(fileID, 3, 1, 'int');
%! fclose(fileID);
%! delete(filename);
%!
%! assert(isa(data, 'int32'));
%! assert(size(data), [3, 1]);
%! assert(data, int32([1; 2; 3]));
%!
%!test #2.2.Корректное чтение блока чисел с плавающей запятой
%! testData = sprintf('1.0 \n2.0\n 3.0');
%! filename = setupTestData(testData);
%!
%! fileID = fopen(filename, 'r');
%! data = parseDataBlock(fileID, 3, 1, 'double');
%! fclose(fileID);
%! delete(filename);
%!
%! assert(isa(data, 'double'));
%! assert(size(data), [3, 1]);
%! assert(data, [1.0; 2.0; 3.0]);
%!
%!test #2.3.Пустой блок
%! filename = setupTestData('');
%!
%! fileID = fopen(filename, 'r');
%! fail("parseDataBlock(fileID, 0, 0, 'int')","input must be positive");
%! fclose(fileID);
%! delete(filename);
%!
%!test #2.4.Чтение нескольких блоков подряд
%! testData = sprintf('1 2 3\n 4 5 6\n1.0 \n2.0\n 3.0');
%! filename = setupTestData(testData);
%!
%! fileID = fopen(filename, 'r');
%! data1 = parseDataBlock(fileID, 2, 3, 'int');
%! data2 = parseDataBlock(fileID, 3, 1, 'double');
%! fclose(fileID);
%! delete(filename);
%!
%! assert(isa(data1, 'int32'));
%! assert(size(data1), [2, 3]);
%! assert(data1, int32([1 2 3; 4 5 6]));
%! assert(isa(data2, 'double'));
%! assert(size(data2), [3, 1]);
%! assert(data2, [1.0; 2.0; 3.0]);
%!     #2.5.Некоректный файловый дескриптор
%!error <invalid file descriptor of block> parseDataBlock(-1, 2, 2, 'int');
%!
%!test #2.6.EOF в одном блоке
%! filename = setupTestData('');
%!
%! fileID = fopen(filename, 'r');
%! fail("parseDataBlock(fileID, 3, 1, 'int')","unexpected EOF on line 1 of block");
%! fclose(fileID);
%! delete(filename);
%!
%!test #2.7.EOF в последнем блоке
%! filename = setupTestData('1');
%!
%! fileID = fopen(filename, 'r');
%! parseDataBlock(fileID, 1, 1, 'int');
%! fail("parseDataBlock(fileID, 3, 1, 'int')","unexpected EOF on line 1 of block");
%! fclose(fileID);
%! delete(filename);
%!
%!test #2.8.Внутренняя ошибка парсера
%! testData = sprintf('1 \na\n 3');
%! filename = setupTestData(testData);
%!
%! fileID = fopen(filename, 'r');
%! fail("parseDataBlock(fileID, 3, 1, 'int')","invalid symbol: a on line 2 of block");
%! fclose(fileID);
%! delete(filename);
%!
%!test #2.9.Неверный тип данных
%! testData = sprintf('1 \n2\n 3');
%! filename = setupTestData(testData);
%!
%! fail("parseDataBlock(fileID, 3, 1, 'iint')", "unsupported type: iint of block");
%! fclose(fileID);
%! delete(filename);
%!
%% importFromFile
%!     #3.1 Некорректный дескриптор файла
%!error <file not found>
%! importFromFile('not_found.txt');
%%
%!test #3.2 Неизвестный формат файла
%! filename = setupTestData('test','.not_supported');
%!
%! fail("importFromFile(filename)","Unsupported format: .not_supported");
%!
%! delete(filename);
%!
%% Тесты 4ekm
%!test #4.1.Корректная загрузка файла
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
%%     #4.2.Несуществующий файл
%!error <file not found>
%! importFromFile('non_existent_file.4ekm');
%%
%!test #4.3.Пустой файл
%! filename = setupTestData('', '.4ekm');
%!
%! fail("importFromFile(filename)","unexpected EOF on line 1 of block header");
%!
%! delete(filename);
%!
%!test #4.4.Неполные данные узлов
%!
%! testData = sprintf('8 \n1 \n0.000000   0.000000 \n0.250000   0.000000   \n0.500000   0.000000 \n0.750000   0.000000 \n1.000000   0.000000   \n0.000000   0.250000 \n   0.250000   0.250000 \n0.500000   0.250000\n 1      2      3      4     5     6     7     8');
%! filename = setupTestData(testData,'.4ekm');
%!
%! fail("importFromFile(filename)","expected 3 numbers, but 2 is read on line 1 of block nodes");
%!
%! delete(filename);
%!
%!test #4.5.Неполные данные элементов
%!
%! testData = sprintf('8 \n2 \n0.000000   0.000000   0.000000\n0.250000   0.000000   0.000000 \n0.500000   0.000000   0.000000\n0.750000   0.000000   0.000000\n1.000000   0.000000   0.000000\n0.000000   0.250000   0.000000\n   0.250000   0.250000   0.000000\n0.500000   0.250000   0.000000\n 1      2      3      4     5     6     7     8');
%! filename = setupTestData(testData, '.4ekm');
%!
%! fail("importFromFile(filename)","unexpected EOF on line 2 of block hexas");
%!
%! delete(filename);
%!
%!xtest #4.6.Несуществующие узлы в элементах
%!
%! testData = sprintf('8 \n1 \n0.000000   0.000000   0.000000\n0.250000   0.000000   0.000000 \n0.500000   0.000000   0.000000\n0.750000   0.000000   0.000000\n1.000000   0.000000   0.000000\n0.000000   0.250000   0.000000\n   0.250000   0.250000   0.000000\n0.500000   0.250000   0.000000\n 11      12      13      14     5     6     7    11 ');
%! filename = setupTestData(testData,'.4ekm');
%!
%! fail("importFromFile(filename)","Non existed nodes with numbers [11 12 13 14] finding in elements 1");
%!
%! delete(filename);
%!
%% Тесты romanov
%!test #5.1.Корректная загрузка файла
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
%%     #5.2.Несуществующий файл
%!error <file not found>
%! importFromFile('non_existent_file.romanov');
%%
%!test #5.3.Пустой файл
%! filename = setupTestData('', '.romanov');
%!
%! fail("importFromFile(filename)","unexpected EOF on line 1 of block header");
%!
%! delete(filename);
%!
%!test #5.4.Неполные данные узлов
%!
%! testData = sprintf('8 \n1 \n1 0.000000   0.000000 \n2 0.250000   0.000000   \n3 0.500000   0.000000 \n4 0.750000   0.000000 \n5 1.000000   0.000000   \n6 0.000000   0.250000 \n7   0.250000   0.250000 \n8 0.500000   0.250000\n1 1      2      3      4     5     6     7     8');
%! filename = setupTestData(testData,'.romanov');
%!
%! fail("importFromFile(filename)","expected 4 numbers, but 3 is read on line 1 of block nodes");
%!
%! delete(filename);
%!
%!test #5.5.Неполные данные элементов
%!
%! testData = sprintf('8 \n2 \n1 0.000000   0.000000   0.000000\n2 0.250000   0.000000   0.000000 \n3 0.500000   0.000000   0.000000\n4 0.750000   0.000000   0.000000\n5 1.000000   0.000000   0.000000\n6 0.000000   0.250000   0.000000\n7    0.250000   0.250000   0.000000\n8 0.500000   0.250000   0.000000\n 1 1      2      3      4     5     6     7     8');
%! filename = setupTestData(testData, '.romanov');
%!
%! fail("importFromFile(filename)","unexpected EOF on line 2 of block hexas");
%!
%! delete(filename);
%!
%!xtest #5.6.Несуществующие узлы в элементах
%!
%! testData = sprintf('8 \n1 \n1 0.000000   0.000000   0.000000\n2 0.250000   0.000000   0.000000 \n3 0.500000   0.000000   0.000000\n4 0.750000   0.000000   0.000000\n5 1.000000   0.000000   0.000000\n6 0.000000   0.250000   0.000000\n7    0.250000   0.250000   0.000000\n8 0.500000   0.250000   0.000000\n 1 11      12      13      14     5     6     7     11');
%! filename = setupTestData(testData,'.romanov');
%!
%! fail("importFromFile(filename)","Non existed nodes with numbers [11 12 13 14] finding in elements 1");
%!
%! delete(filename);
%!
