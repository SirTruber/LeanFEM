classdef Grid < handle
    properties
        mesh,
        elem,
        renderer
    end
    methods
        function obj = Grid(filename)
            fileID = fopen(filename,"r");

            mesh_size = sscanf(fgetl(fileID),'%d');
            elem_size = sscanf(fgetl(fileID),'%d');

            obj.mesh = zeros(mesh_size,3,'double');
            obj.elem = zeros(elem_size,8,'int32');
            for i = 1:mesh_size
                obj.mesh(i,1:3) = sscanf(fgetl(fileID),'%lf')';
            end
            for i = 1:elem_size
                obj.elem(i,1:8) = sscanf(fgetl(fileID),'%d')';
            end
            fclose(fileID);
            obj.renderer.h = -1;
        end

        function save(obj,filename)
            fileID = fopen(filename,"w");

            mesh_size = rows(obj.mesh);
            elem_size = rows(obj.elem);

            fprintf(fileID,'%d\n',mesh_size);
            fprintf(fileID,'%d\n',elem_size);

            mesh_spec = '%11f%11f%11f\n';
            elem_spec = '%7d%7d%7d%7d%7d%7d%7d%7d\n';
            for i = 1:mesh_size
                fprintf(fileID,mesh_spec,obj.mesh(i,:));
            end
            for i = 1:elem_size
                fprintf(fileID,elem_spec,obj.elem(i,:));
            end
            fclose(fileID);
        end

        function n = points(obj,ind)
            n = obj.mesh(obj.elem(ind,:)',:);
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

        function show(obj)
            if (isgraphics(obj.renderer.h))
                return;
            end
            a = [1 4 3 2; 5 6 7 8; 1 2 6 5; 4 8 7 3; 2 3 7 6; 4 1 5 8];

            obj.renderer.faces = reshape(obj.elem(:,a),[],4);

            [u,ida,idx] = unique(sort(obj.renderer.faces,2),"rows");
            count = histc(idx,1:rows(u));

            obj.renderer.faces = obj.renderer.faces(ida(count == 1),:);
            obj.renderer.faces_to_elem = idivide(ida(count == 1) - 1,int16(6)) + 1;

            obj.renderer.h = patch("Faces", obj.renderer.faces, "Vertices", obj.mesh, 'FaceColor','flat');
        end
    end
end
