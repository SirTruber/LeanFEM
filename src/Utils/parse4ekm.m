function [nodes,hexas] = parse4ekm(fileID)
    [numberOfNodes, numberOfHexas] = readHeader(fileID);
    nodes = readNodes(fileID, numberOfNodes);
    hexas = readHexas(fileID, numberOfHexas);
end

function [numberOfNodes, numberOfHexas] = readHeader(fileID)
    [numberOfNodes; numberOfHexas] = parseDataBlock(fileID,'int', 2, 1);
end

function nodes = readNodes(fileID, numberOfNodes)
    nodes = parseDataBlock(fileID, 'double', numberOfNodes, 3);
end

function hexas = readHexas(fileID, numberOfHexas)
    hexas = parseDataBlock(fileID, 'int', numberOfHexas, 8);
end

function data = parseDataBlock(fileID, type, rows, columns)
    validateattributes(rows, {'numeric'}, {'scalar', 'integer', 'positive'});
    validateattributes(columns, {'numeric'}, {'scalar', 'integer', 'positive'});
    [dataType, spec] = correctDataType(type);

    data = zeros(rows, columns, dataType);
    for i = 1:rows
        line = fgetl(fileID);
        if ~ischar(line)
            error('unexpected EOF on line %d',i);
        end
        try
            data(i,:) = parseLine(line, columns, spec);
        catch err
            error('%s on line %d', err.message, i);
        end
    end
end

function values = parseLine(line, length, spec)
    [values, num, err, index] = sscanf(line, spec, [1, length]);

    if ~isempty(err)
        errorFromSscanf(line, index);
    end

    if num ~= length
        error('Expected %d symbols, but %d is read', length, num);
    end
end

function [dataType, spec] = correctDataType(type)
    type = lower(type);

    typeSpecs = struct(...
        'int',    struct('dataType', 'int32',  'spec', '%d'), ...
        'float',  struct('dataType', 'single', 'spec', '%f'), ...
        'double', struct('dataType', 'double', 'spec', '%lf'), ...
        'char',   struct('dataType', 'char',   'spec', '%c') ...
    );

    if isfield(typeSpecs, type)
        specStruct = typeSpecs.(type);
        dataType = specStruct.dataType;
        spec = specStruct.spec;
    else
        error('Unsupported type: %s',type);
    end
end

function errorFromSscanf(line, index)
    if isempty(line)
        error('Empty line');
    end

    if index <= numel(line);
        error('Invalid symbol: %c', line(index));
    end
end

%% correctDataType
%!test #1.Парсер целочисленных строк
%! [dataType] = correctDataType('int');
%! assert(dataType,'int32');
%! assert(spec,'%d');
%!test #2.Парсер строк с плавающей запятой
%! parser = Parser('float',12);
%! assert(parser.dataType,'single');
%! assert(parser.length,12);
%! assert(parser.spec,'%f');
%!     #3.Неподдерживаемый тип
%!error <Unsupported type: iiinntt> Parser('iiinntt',2);
%!     #4.Нецелый размер строки
%!error <input must be integer> Parser('single',2.4);
%!     #5.Отрицательный размер строки
%!error <input must be positive> Parser('single',-2);
%%
%% parseLine
%!test #1.Корректные целые числа
%! res = parseLine('1 2 3',3,'%d');
%! assert(res,[1 2 3]);
%!
%!test #2.Отрицательные целые числа
%! res = parseLine('-1 -2',2,'%d');
%! assert(res,[-1 -2]);
%!
%!test #3.Корректные числа с плавающей запятой
%! res = parseLine("1.0 2.5 -3.7", 3, '%f');
%! assert(res, [1.0, 2.5, -3.7], 1e-6);
%!
%!test #4.Числа в экспоненциальной записи
%! res = parseLine("1e2 2.5e-1 3.7E+3", 3, '%f');
%! assert(res, [100, 0.25, 3700], 1e-6);
%!
%!test #5.Смешанные числа
%! res = parseLine("1 2.0 3", 3, '%f');
%! assert(res, [1.0, 2.0, 3.0], 1e-6);
%!
%!     #6.Недостаточное колличество чисел
%!error <Expected 3 symbols, but 2 is read> parseLine("1 2", 3, '%f');
%!
%!test #7.Лишние числа игнорируются
%! res = parseLine("1 2 3 4", 3, '%d');
%! assert(res, [1, 2, 3]);
%!
%!     #8.Некорректные символы в начале
%!error <Invalid symbol: a> parseLine("a", 1, '%d');
%!
%!     #9.Некорректные символы в середине
%!error <Invalid symbol: a> parseLine("1 a 3", 3, '%d');
%!
%!     #10.Пустая строка
%!error <Empty line> parseLine("", 1, '%d');
%!
%!test #11.Строка с пробелами
%! res = parseLine("   1  2.5  -3   ", 3, '%f');
%! assert(res, [1.0, 2.5, -3.0], 1e-6);
%!
%!test #12.Разные разделители
%! res = parseLine("1\t2.5\t3", 3, '%f');
%! assert(res, [1.0, 2.5, 3.0], 1e-6);
%%
%%
