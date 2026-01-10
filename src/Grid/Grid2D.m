classdef Grid2D < GridData
    properties
        quads   % Четырехугольные элементы [4xN]
    end
    methods
        function e = elements(obj,ind) 
            e = obj.quads(:,ind);
        end
        function m = numElements(obj)
            m = size(obj.quads,2);
        end
        function p = points(obj,ind)
            p = obj.nodes(1:2,obj.quads(:,ind));
         end
    end
end