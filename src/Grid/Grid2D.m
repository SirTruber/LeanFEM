classdef Grid2D < GridData
    properties
        quads   % Четырехугольные элементы [4xN]
    end
    methods
        function e = elements(obj,ind) 
            if nargin == 1
                ind = 1:obj.numElements();
            end
            e = obj.quads(:,ind);
        end
        function m = numElements(obj)
            m = size(obj.quads,2);
        end
        function p = points(obj,ind)
            if nargin == 1
                e = obj.elements();
            else
                e = obj.elements(ind);
            end
            p = obj.nodes(1:2,e);
        end

        function edge = generateEdge(obj)
            a = ...
            [1 2; ...
             2 3; ...
             3 4; ...  
             4 1];

            facet = reshape(obj.quads(a',:),size(a,2),[]); %Собираем все рёбра квадов
            
            [~,ida,idx] = unique(sort(facet)',"rows","stable"); %Оставляем только уникальные
            count = accumarray(idx,1);

            edge = facet(:,ida(count == 1)); % И которые встречаются только один раз
         end
    end
end