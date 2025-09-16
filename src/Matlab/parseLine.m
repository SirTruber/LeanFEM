function values = parseLine(line, length, spec)
    [values, num, err, index] = sscanf(line,spec,[1, length]);

    if ~isempty(err)
        errorFromSscanf(index,line,spec);
    end

    if num ~= length
        error('expected %d numbers, but %d is read', length, num);
    end
end

function errorFromSscanf(index, line, spec)
    if isempty(line)
        error('empty line');
    end

    if index <= numel(line);
        error('invalid symbol: %c', line(index));
    end
end

%%
%test #1.Корректные целые числа
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
%!error <expected 3 numbers, but 2 is read> parseLine("1 2", 3, '%f');
%!
%!test #7.Лишние числа игнорируются
%! res = parseLine("1 2 3 4", 3, '%d');
%! assert(res, [1, 2, 3]);
%!
%!     #8.Некорректные символы в начале
%!error <invalid symbol: a> parseLine("a", 1, '%d');
%!
%!     #9.Некорректные символы в середине
%!error <invalid symbol: a> parseLine("1 a 3", 3, '%d');
%!
%!     #10.Пустая строка
%!error <empty line> parseLine("", 1, '%d');
%!
%!test #11.Строка с пробелами
%! res = parseLine("   1  2.5  -3   ", 3, '%f');
%! assert(res, [1.0, 2.5, -3.0], 1e-6);
%!
%!test #12.Разные разделители
%! res = parseLine("1\t2.5\t3", 3, '%f');
%! assert(res, [1.0, 2.5, 3.0], 1e-6);
%%
