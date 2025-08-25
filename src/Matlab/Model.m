classdef Model < handle
    properties
        analysisType = 'static'
        geometry
        regions

        faceBC
        edgeBC
        vertexBC

        cellLoad
        faceLoad
        edgeLoad
        vertexLoad

        cellIC
        faceIC
        edgeIC
        vertexIC
    end
    methods
        function obj = Model(geometry)
        end

        function region = addRegion(obj,elemID,feSpace)
        end

        function disp(obj)
        end

        function result = solve(obj, regionID)
        end

        function changeTask(obj)
        end

        function h = plot(obj, varargin)
            h = obj.geometry.plot(varargin);
        end

        function h = mesh(obj, varargin)
            h = obj.geometry.mesh(varargin);
        end
    end
end

%!test создание модели по готовой геометрии
%!
%!test создание пустой модели с добавлением геометрии впоследствии
%!
%!test добавление региона с моментными элементами
%!
%!test добавление региона с ажурными элементами
%!
%!test добавление региона с несуществующим типом элемента
%!
%!test добавление региона с несуществующими узлами
%!
%!test добавление региона с дублирующимися элементами
%!
%!test добавление граничных условий на ячейку
%!
%!test добавление граничных условий на грань
%!
%!test добавление граничных условий на вершину
%
%!test добавление граничных условий к несуществующим элементам
%!
%!test удаление граничных условий
%!
%!test добавление гравитации на ячейку
%!
%!test добавление давления на грань
%!
%!test добавление сил на вершину
%!
%!test добавление нагрузок к несуществующим элементам
%!
%!test смена типа задачи
%!
%!test решение статической задачи с одним регионом
%!
%!test решение динамической задачи с одним регионом
%!
%!test решение статической задачи с несколькими регионами
%!
%!test решение динамической задачи с несколькими регионами
%!
%!test запуск решателя с неполной информацией
