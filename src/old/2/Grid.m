classdef Grid < handle
    properties
        name,
        nodes,
        quads,
        hexas,
        regions
    end
    methods
        function generateQuads(obj)
            a = [1 4 3 2; 5 6 7 8; 1 2 6 5; 4 8 7 3; 2 3 7 6; 4 1 5 8];

            obj.quads = reshape(obj.hexas(:,a),[],4);

            [u,ida,idx] = unique(sort(obj.quads,2),"rows");
            count = histc(idx,1:rows(u));

            obj.quads = obj.quads(ida(count == 1),:);
            %obj.renderer.faces_to_elem = idivide(ida(count == 1) - 1,int16(6)) + 1;
        end

        function add_region(obj, dimension, region_name, elements, material_name, bc)
            new_region = Region(region_name, elements, material_name, bc);
            new_region.calculate_nodes(obj);  % Привязка к сетке
            obj.regions(region_name) = new_region;
        end

        function p = points(obj,ind)
            p = obj.nodes(obj.hexas(ind,:)',:);
        end

        function h = minHeight(obj,ind)
            nodes = obj.points(ind);
            n = length(ind);
            edges = [1 2; 2 3; 3 4; 4 1; 5 6; 6 7; 7 8; 8 5; 1 5; 2 6; 3 7; 4 8];
            if n ~= 1
                edges = repmat(edges,n,1) + repmat(repelem(8 * (0:(n-1))',rows(edges)),1,columns(edges));
            end
            edges = nodes(edges(:,2),:) - nodes(edges(:,1),:);
            len = sqrt(sum(edges.^2,2));
            h = min(nonzeros(len));
        end

        function v = volume(obj,ind)
            nodes = obj.points(ind);
            n = length(ind);
            tetraedron = [1 3 6 8; 1 2 6 3; 1 3 8 4; 1 6 5 8; 3 6 8 7];
            if n ~= 1
                tetraedron = repmat(tetraedron,n,1) + repmat(repelem(8 * (0:(n-1))',rows(tetraedron)),1,columns(tetraedron));
            end
            determinant = arrayfun(@(i) det([nodes(tetraedron(i,:),:) ones(4,1)]), 1:rows(tetraedron));
            v = 1/6 * sum(determinant);
        end
    end
end
