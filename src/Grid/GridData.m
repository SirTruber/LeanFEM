classdef GridData < handle
    properties
        name    % Уникальный идентификатор (строка)
        nodes   % Координаты узлов сетки [3xM]
    end
    methods (Abstract)
         function e = elements(obj,ind) end % Возвращает номера узлов элемента ind
         function m = numElements(obj) end % Возвращает число элементов
         function p = points(obj,ind) end % Возвращает координаты узлов элемента ind
    end

    methods
        function n = numNodes(obj) % Возвращает число узлов
            n = size(obj.nodes,2);
        end

        function [Pmin,Pmax] = bbox(obj) % Возвращает минимальную и максимальную координаты ограничивающего куба для быстрого определения положения и размера объекта
            Pmin = min(obj.nodes,[],2);
            Pmax = max(obj.nodes,[],2);
        end

        function [c,r] = bsphere(obj) % Возвращает центр и радиус ограничивающей сферы для быстрого определения положения и размера объекта
            c = mean(obj.nodes,2); % Центр = среднее арифметрическое координат узлов
            t = obj.nodes - c;
            r = max(sqrt(sum(t.^2,1))); % Радиус = максимум расстояний от центра до координаты
        end
    end
end
