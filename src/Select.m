classdef Select < handle
    properties
        region
    end

    methods(Static)
        function selected = select(obj, type, target)
            %selected   индексы объектов типа type, удовлетворяющих target
            %type -     выбор условия: 'nodes' - по координатам, 'quads' - по четырёхугольникам ,'hexas' - по гексаэдрам
            %target     функция-предикат, принимает массив координат соответствующего размера
            if ~isa(target, 'function_handle')
                return
            end
            mask = [];
            switch lower(type)
                case 'nodes'
                    mask = arrayfun(@(i) target(obj.nodes(i,:)), 1:size(obj.nodes,1));
                case 'quads'
                    mask = arrayfun(@(i) target(obj.nodes(obj.quads(i,:),:)), 1:size(obj.quads,1));
                case 'hexas'
                    mask = arrayfun(@(i) target(obj.nodes(obj.hexas(i,:),:)), 1:size(obj.hexas,1));
            end
            selected = find(mask);
        end
    end
    methods
        function obj = Select(type)
            obj.region = Region;
            obj.region.selectionType = lower(type);
        end

        function dest = from(source, mesh)
            selected = source.region.selectionType;
            if ~isfield(mesh, selected)
                error('in mesh no such field as %s', selected);
            end
            source.region.parent = mesh;
            source.region.mask = ones(size(mesh.(selected),1),1,"logical");
        end
    end
end

%!function mesh = setupTestMesh
%! mesh = Mesh.import('../grid/setk_b_t.4ekm');
%!endfunction
%!
%!test #1.Создание региона одномерных элементов(узлов)
%!
%! mesh = setupTestMesh();
%! reg = Select('nodes').from(mesh).createRegion();
%!
%! assert()
%!
%!test #2.Попытка доступа к несуществующим элементам
%!
%! mesh = setupTestMesh();
%! fail("Select('quads').from(mesh)");
%!
%!test #3.Создание региона объёмных элементов
%!
%! mesh = setupTestMesh();
%! Select('quads').from(mesh);
%!
%!test #4.Выбор элементов по номерам
%!
%! mesh = setupTestMesh();
%!
%! reg = Select('hexas').from(mesh).byID([1, 2, 3]);
%!
%! assert();
%!
%!test #5.Выбор элементов по координатам
%!
%!test #6.Выбор элементов в кубической области
%!
%!test #7.Выбор элементов в сфере
%!
%!test #8.Выбор элементов на плоскости
%!
%!test #9.Выбор элементов на поверхности
%!
%!test #10.Выбор по математическому выражению
%!
%!test #11.Объединение регионов
%!
%!test #12.Пересечение регионов
%!
%!test #13.Вычитание регионов
%!
%!test #14.Инвертирование выбора
%!
%!test #15.Очистка региона
%!
%!test #16.Получение координат узлов элементов
%!
%!test #17.Пустой регион
%!
%!test #18.Регион, содержащий все элементы
%!
%!test #19.Выбор по нескольким условиям
%
%!test #20.Выбор несуществующих узлов
