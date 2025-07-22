classdef IO
    methods (Static)
        % Загрузка данных из файла
        function [data,format] = load(filename)
            [~, ~, ext] = fileparts(filename);
            switch lower(ext)
                case '.4ekm'
                    data = IOMesh.load4ekm(filename);
                    format = 'grid';
                case '.msh'
                    data = IOMesh.loadGmsh(filename);
                    format = 'grid';
                case '.vtk'
                    data = IOMesh.loadVTK(filename);
                    format = 'grid';
                otherwise
                    error('Unsupported format: %s', ext);
            end
        end

        function save(data, filename)
        % Сохранение данных в файл
            [~, ~, ext] = fileparts(filename);
            switch lower(ext)
                case '.4ekm'
                    IOMesh.save4ekm(data, filename);
                case '.msh'
                    IOMesh.saveGmsh(data, filename);
                case '.vtk'
                    IOMesh.saveVTK(data, filename);
                otherwise
                    error('Unsupported format: %s', ext);
            end
        end

        function grid = load4ekm(filename)
            grid = GridData;
            grid.regions = containers.Map('KeyType', 'char', 'ValueType', 'any');
            [~,grid.name,~] = fileparts(filename);
            fileID = fopen(filename,"r");

            nodes_size = sscanf(fgetl(fileID),'%d');
            hexas_size = sscanf(fgetl(fileID),'%d');

            grid.nodes = zeros(nodes_size ,3,'double');
            grid.hexas = zeros(hexas_size ,8,'int32');
            for i = 1:nodes_size
                grid.nodes(i,1:3) = sscanf(fgetl(fileID),'%lf')';
            end
            for i = 1:hexas_size
                grid.hexas(i,1:8) = sscanf(fgetl(fileID),'%d')';
            end
            fclose(fileID);
            grid.generateQuads();
        end

        function save4ekm(grid,filename)
            fileID = fopen(filename,"w");

            nodes_size = rows(grid.nodes);
            hexas_size = rows(grid.hexas);

            fprintf(fileID,'%d\n',nodes_size);
            fprintf(fileID,'%d\n',hexas_size);

            nodes_spec = '%11f%11f%11f\n';
            hexas_spec = '%7d%7d%7d%7d%7d%7d%7d%7d\n';
            for i = 1:nodes_size
                fprintf(fileID,nodes_spec,grid.nodes(i,:));
            end
            for i = 1:hexas_size
                fprintf(fileID,hexas_spec,grid.hexas(i,:));
            end
            fclose(fileID);
        end

        function grid = loadGmsh(filename)
            grid = GridData;
            grid.regions = containers.Map('KeyType', 'char', 'ValueType', 'any');
            [~,grid.name,~] = fileparts(filename);
            fileID = fopen(filename,"r");
            %TODO
            fclose(fileID);
        end

        function saveGmsh(grid, filename)
            fileID = fopen(filename,"w");
            %TODO
            fclose(fileID);
        end
    end
end
