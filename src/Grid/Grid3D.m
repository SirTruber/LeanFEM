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
                e = obj.elements();
             else
                e = obj.elements(ind);
             end
             p = obj.nodes(:,e);
         end

         function quads_to_hexas = generateQuads(obj,hexas)
             if nargin == 1
                 hexas = obj.hexas;
             end
             a = ...
             [1 2 3 4;...  % Грань 1 (нижняя)
              5 8 7 6;...  % Грань 2 (верхняя)
              1 5 6 2;...  % Грань 3 (передняя)
              4 3 7 8;...  % Грань 4 (задняя)
              2 6 7 3;...  % Грань 5 (правая)
              1 4 8 5];    % Грань 6 (левая)
 
             facet = reshape(hexas(a',:),size(a,2),[]); %Собираем все грани гексаэдров
             quads_to_hexas = repelem(1:obj.numElements(),6)';

             [~,ida,idx] = unique(sort(facet)',"rows","stable"); %Оставляем только уникальные
             count = accumarray(idx,1);

             obj.quads = facet(:,ida(count == 1)); % И которые встречаются только один раз %WARNING Затирает результаты

            quads_to_hexas = quads_to_hexas(ida(count == 1));
         end
         function min_edge = minimalSize(obj, hexas)
             if nargin == 1
                 hexas = obj.hexas;
             end
            a = ...
             [1 2;...
              2 3;...
              3 4;...
              4 1;...
              5 6;...
              6 7;...
              7 8;...
              8 1;...
              1 5;...
              2 6;...
              3 7;...
              4 8];

            edgesNodes = reshape(hexas(a',:),size(a,2),[]); %Собираем все ребра гексаэдров
            edgesVec = obj.nodes(:,edgesNodes(1,:)) - obj.nodes(:,edgesNodes(2,:));
            edgesLen = sqrt(sum(edgesVec.^2));
            min_edge = min(nonzeros(edgesLen));
         end
    end
end