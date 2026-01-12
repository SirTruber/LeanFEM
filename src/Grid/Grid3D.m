classdef Grid3D < GridData
    properties
        quads   % Четырехугольные элементы(генерируются автоматически) [4xN]
        hexas   % Гексаэдральные элементы, [8xK]
    end
    methods
        function e = elements(obj,ind)
            if nargin == 1
                ind = 1:obj.numElements();
            end
            e = obj.hexas(:,ind);
        end

         function m = numElements(obj)
            m = size(obj.hexas,2);
         end

         function p = points(obj,ind)
             if nargin == 1
                ind = 1:obj.numNodes();
            end
            p = obj.nodes(:,obj.hexas(:,ind));
         end

         function quads_to_hexas = generateQuads(obj)
            a = ...
            [1 2 3 4;...  % Грань 1 (нижняя)
             5 8 7 6;...  % Грань 2 (верхняя)
             1 5 6 2;...  % Грань 3 (передняя)
             4 3 7 8;...  % Грань 4 (задняя)
             2 6 7 3;...  % Грань 5 (правая)
             1 4 8 5];    % Грань 6 (левая)

            facet = reshape(obj.hexas(a',:),4,[]); %Собираем все грани гексаэдров
            quads_to_hexas = repelem(1:obj.numElements(),6)';

            [~,ida,idx] = unique(sort(facet)',"rows","stable"); %Оставляем только уникальные
            count = accumarray(idx,1);

            obj.quads = facet(:,ida(count == 1)); % И которые встречаются только один раз

            quads_to_hexas = quads_to_hexas(ida(count == 1));
         end
    end
end