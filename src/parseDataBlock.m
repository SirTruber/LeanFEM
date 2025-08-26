function data = parseDataBlock(fileID, rows, columns, type)
    validateParseAttribute(fileID, rows, columns, type);

    [dataType, spec] = getTypeParameters(type);

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

function validateParseAttribute(fileID, rows, columns, type)
    if ~is_valid_file_id(fileID)
        error('invalid file descriptor');
    end
    validateattributes(rows, {'numeric'}, {'scalar', 'integer', 'positive'});
    validateattributes(columns, {'numeric'}, {'scalar', 'integer', 'positive'});
    if ~isTypeSupported(type)
        error('unsupported type: %s',type);
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

%!function filename = setupTestData(testData, format)
%! filename = [tempname(), format];
%! fileID = fopen(filename, 'w');
%! fprintf(fileID, testData);
%! fclose(fileID);
%!endfunction
%%
%!test #1.Корректное чтение блока целых чисел
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
%!test #2.Корректное чтение блока чисел с плавающей запятой
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
%!test #3.Пустой блок
%! filename = setupTestData('');
%!
%! fileID = fopen(filename, 'r');
%! fail("parseDataBlock(fileID, 0, 0, 'int')","input must be positive");
%! fclose(fileID);
%! delete(filename);
%!
%!test #4.Чтение нескольких блоков подряд
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
%!     #5.Некоректный файловый дескриптор
%!error <invalid file descriptor> parseDataBlock(-1, 2, 2, 'int');
%!
%!test #6.EOF в одном блоке
%! filename = setupTestData('');
%!
%! fileID = fopen(filename, 'r');
%! fail("parseDataBlock(fileID, 3, 1, 'int')","unexpected EOF on line 1");
%! fclose(fileID);
%! delete(filename);
%!
%!test #7.EOF в последнем блоке
%! filename = setupTestData('1');
%!
%! fileID = fopen(filename, 'r');
%! parseDataBlock(fileID, 1, 1, 'int');
%! fail("parseDataBlock(fileID, 3, 1, 'int')","unexpected EOF on line 1");
%! fclose(fileID);
%! delete(filename);
%!
%!test #8.Внутренняя ошибка парсера
%! testData = sprintf('1 \na\n 3');
%! filename = setupTestData(testData);
%!
%! fileID = fopen(filename, 'r');
%! fail("parseDataBlock(fileID, 3, 1, 'int')","invalid symbol: a on line 2");
%! fclose(fileID);
%! delete(filename);
%!
%!test #9.Неверный тип данных
%! testData = sprintf('1 \n2\n 3');
%! filename = setupTestData(testData);
%!
%! fileID = fopen(filename);
%! fail("parseDataBlock(fileID, 3, 1, 'iint')", "unsupported type: iint of");
%! fclose(fileID);
%! delete(filename);
%!
