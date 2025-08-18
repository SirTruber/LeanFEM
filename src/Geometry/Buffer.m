classdef Buffer < handle
    properties
        type = 'int32';
        size = 0;
        data = int32([]);
    end
    methods
        function obj = Buffer(type, data, size)
            if ~isTypeSupported(type)
                error('unsupported type: %s ',type);
            end

            dataSize = numel(data);
            if nargout == 2
                size = dataSize;
            end

            if dataSize > size
                warning('incorrect buffer size');
            end

            typeSpec = getType.(lower(type));
            obj.type = typeSpec.dataType;
            obj.size = max(dataSize,size);
            obj.data(1:dataSize) = cast(data(:),obj.type);
        end
    end
end

function isValid = isTypeSupported(type)
    isValid = isfield(getType, lower(type));
end

function typeSpec = getType()
    typeSpec = struct(...
        'int',    struct('dataType', 'int32'), ...
        'float',  struct('dataType', 'single'), ...
        'double', struct('dataType', 'double'), ...
        'char',   struct('dataType', 'char')...
    );
end



%!test #1.Создание буфера с плавающей запятой
%!
%! data = [1.5 2.0 3.3 4.1];
%! buffer = Buffer('float', data);
%!
%! assert(buffer.type, 'single');
%! assert(buffer.size, 4);
%! assert(buffer.data,single([1.5;2.0;3.3;4.1]));
%!
%!test #2.Создание целочисленного буфера
%!
%! data = [1 2 3];
%! buffer = Buffer('int', data);
%!
%! assert(buffer.type, 'int32');
%! assert(buffer.size, 3);
%! assert(buffer.data,int32([1; 2; 3]));
%!
%!test #3.Создание пустого буфера
%!
%! buffer = Buffer;
%!
%! assert(buffer.size, 0);
%! assert(isempty(buffer.data));
%!
%!test #4.Предварительная аллокация
%!
%! buffer = Buffer('int', [], 3);
%!
%! assert(buffer.size,3);
%! assert(buffer.data,int32([0; 0; 0]));
%!
%!test #5.Обновление буфера
%!
%! buffer = Buffer('int',[],3);
%!
%! buffer.load([1 2 3]);
%!
%! assert(buffer.data, int32([1;2;3;0;0]));
%!
%!test #5.Динамическое расширение при обновлении
%!
%! buffer = Buffer('int',[],1);
%!
%! buffer.load([1 2 3]);
%!
%! assert(buffer.size, 3);
%!
%!test #6.Копия ссылки на буфер
%!
%! source = Buffer('int',[1 2 3]);
%! dest = source;
%! dest.data(2) = 0;
%!
%! assert(source.data(2), 0);
%!
%!test #7.Глубокая копия буфера
%!
%! source = Buffer('int',[1 2 3]);
%! dest = copy(source);
%! dest.data(2) = 0;
%!
%! assert(source.data(2), 2);
%! assert(dest.data(2), 0);
%!
%!test #8.Удаление буфера
%!
%! buffer = Buffer('int',[1 2 3]);
%! buffer.clear();
%!
%! assert(buffer.type, 'int32');
%! assert(buffer.size, 0);
%! assert(isempty(buffer.data));
%!
%!    #9.Некоректный размер данных
%!warning <incorrect buffer size> Buffer('int',[1 2 3],1);
%!
%!    #10.Некоректный тип данных
%!error <unsupported type: iint> Buffer('iint');
%!
