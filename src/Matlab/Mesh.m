classdef Mesh < handle
    properties
        nodes
        hexas
    end
    methods
        function elemID = findElements(mesh,findType,arg1,arg2)
        end

        function nodeID = findNodes(mesh,findType,arg1,arg2)
        end

        function coord = points(mesh, elemID)
        end

        function validate(mesh)
        end
    end
end

%!test поиск элементов по ID
%!
%!test поиск элементов в box
%!
%!test поиск элементов в радиусе
%!
%!test поиск элементов, которые прикреплены к определённым узлам
%!
%!test поиск элементов по предикату
%!
%!test поиск элементов по неправильному условию
%!
%!test поиск узлов по ID
%!
%!test поиск узлов в box
%!
%!test поиск узлов в радиусе
%!
%!test поиск узлов, ближайших к точке
%!
%!test поиск узлов по предикату
%!
%!test поиск узлов по неправильному условию
%!
%!test согласованность поиска по разным функциям
%!
%!test поиск в пустой сетке
%!
%!test поиск в сетке с одним элементом
%!
%!test неправильное число аргументов
%!
%!test поиск с некоректными аргументами
