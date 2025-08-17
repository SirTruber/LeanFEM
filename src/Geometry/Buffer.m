classdef Buffer < handle

end

%!test #1.Создание буфера с плавающей запятой
%!
%! data = [1.5 2.0 3.3 4.1];
%! buffer = Buffer('single', data);
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
%!test #5.Копия ссылки на буфер
%!
%! source = Buffer('int',[1 2 3]);
%! dest = source;
%! dest.data(2) = 0;
%!
%! assert(source.data(2), 0);
%!
%!test #6.Глубокая копия буфера
%!
%! source = Buffer('int',[1 2 3]);
%! dest = copy(source);
%! dest.data(2) = 0;
%!
%! assert(source.data(2), 2);
%! assert(dest.data(2), 0);
%!
%!test #7.Удаление буфера
%!
%! buffer = Buffer('int',[1 2 3]);
%! buffer.clear();
%!
%! assert(buffer.type, 'int32');
%! assert(buffer.size, 0);
%! assert(isempty(buffer.data));
%!
%!test #9.Некоректный размер данных
%!
%!
%!
