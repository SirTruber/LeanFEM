classdef Mesh < handle
    properties
        name    % Уникальный идентификатор (строка)
        nodes   % Координаты узлов сетки [Mx3]
        elements% Структура, у которой название поля является типом элемента
    end
    methods (Static)
        function mesh = import(filename)
            fileID = fopen(filename,"r");
            if ~is_valid_file_id(fileID)
                error('file not found');
            end
            mesh = Mesh;
            [~, mesh.name, ext] = fileparts(filename);
            try
                switch lower(ext)
                    case '.4ekm'
                        [mesh.nodes, mesh.elements.hexas] = parse4ekm(fileID);
                    case '.romanov'
                        [mesh.nodes, mesh.elements.hexas] = parseRomanov(fileID);
                    otherwise
                        error('Unsupported format: %s', ext);
                end
            catch err
                fclose(fileID);
                rethrow(err);
            end
            fclose(fileID);
        end
    end

    methods
        function export(obj, filename, ext)
            fileID = fopen(filename,"w");
            if ~is_valid_file_id(fileID)
                error('file not found');
            end
            switch lower(ext)
                case '.4ekm'
                    write4ekm(fileID, obj);
                case '.romanov'
                    writeRomanov(fileID, obj);
            end
            fclose(fileID);
        end

        function p = points(obj,ind)
            p = obj.nodes(obj.hexas(ind,:)',:);
        end

        function selected = select(obj, type, target)
            %selected   индексы объектов типа type, удовлетворяющих target
            %type -     выбор условия: 'nodes' - по координатам, 'quads' - по четырёхугольникам ,'hexas' - по гексаэдрам
            %target     функция-предикат, принимает массив координат соответствующего размера
            if ~isa(target, 'function_handle')
                return
            end
            mask = [];
            switch lower(type)
                case 'nodes'
                    mask = arrayfun(@(i) target(obj.nodes(i,:)), 1:size(obj.nodes,1));
                case 'quads'
                    mask = arrayfun(@(i) target(obj.nodes(obj.quads(i,:),:)), 1:size(obj.quads,1));
                case 'hexas'
                    mask = arrayfun(@(i) target(obj.nodes(obj.hexas(i,:),:)), 1:size(obj.hexas,1));
            end
            selected = find(mask);
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
    end
end

function [nodes, hexas] = parse4ekm(fileID)
    headerSize = [2;1];
    nodesDim = 3;
    elementDim = 8;
    try
        header = parseDataBlock(fileID, headerSize(1), headerSize(2),'int');
        numberOfNodes = header(1);
        numberOfHexas = header(2);
    catch err
        error('%s header', err.message);
    end
    try
        nodes = parseDataBlock(fileID, numberOfNodes, nodesDim, 'double');
    catch err
        error('%s nodes', err.message);
    end
    try
        hexas = parseDataBlock(fileID, numberOfHexas, elementDim, 'int'); % Нет проверки, все ли узлы существуют, ответственность билдера
    catch err
        error('%s hexas', err.message);
    end
end

function write4ekm(fileID, data)
    numberOfNodes = rows(data.nodes);
    numberOfHexas = rows(data.hexas);

    fprintf(fileID,'%d\n',nodes_size);
    fprintf(fileID,'%d\n',hexas_size);

    nodesSpec = '%11f%11f%11f\n';
    hexasSpec = '%7d%7d%7d%7d%7d%7d%7d%7d\n';
    for i = 1:nodes_size
        fprintf(fileID, nodesSpec, data.nodes(i,:));
    end
    for i = 1:hexas_size
        fprintf(fileID, hexasSpec, data.hexas(i,:));
    end
end

function [nodes, hexas] = parseRomanov(fileID)
    headerSize = [2;1];
    nodesDim = 3;
    elementDim = 8;

    try
        header = parseDataBlock(fileID, headerSize(1), headerSize(2),'int');
        numberOfNodes = header(1);
        numberOfHexas = header(2);
    catch err
        error('%s header', err.message);
    end
    try
        nodes = parseDataBlock(fileID, numberOfNodes, 1 + nodesDim, 'double')(:,2:end);
    catch err
        error('%s nodes', err.message);
    end
    try
        hexas = parseDataBlock(fileID, numberOfHexas, 1 + elementDim, 'int')(:,2:end); % Нет проверки, все ли узлы существуют, ответственность билдера
    catch err
        error('%s hexas', err.message);
    end
end

function writeRomanov(fileID, data)
    numberOfNodes = rows(data.nodes);
    numberOfHexas = rows(data.hexas);

    fprintf(fileID,'%d\n',nodes_size);
    fprintf(fileID,'%d\n',hexas_size);

    nodesSpec = '%d%11f%11f%11f\n';
    hexasSpec = '%d%7d%7d%7d%7d%7d%7d%7d%7d\n';
    for i = 1:nodes_size
        fprintf(fileID, nodesSpec,[i, data.nodes(i,:)]);
    end
    for i = 1:hexas_size
        fprintf(fileID, hexasSpec,[i, data.hexas(i,:)]);
    end
end
%
%         function v = volume(obj,ind)
%             nodes = obj.points(ind);
%             n = length(ind);
%             tetraedron = [1 3 6 8; 1 2 6 3; 1 3 8 4; 1 6 5 8; 3 6 8 7];
%             if n ~= 1
%                 tetraedron = repmat(tetraedron,n,1) + repmat(repelem(8 * (0:(n-1))',rows(tetraedron)),1,columns(tetraedron));
%             end
%             determinant = arrayfun(@(i) det([nodes(tetraedron(i,:),:) ones(4,1)]), 1:rows(tetraedron));
%             v = 1/6 * sum(determinant);
%         end


%!function filename = setupTestData(testData, format)
%! filename = [tempname(), format];
%! fileID = fopen(filename, 'w');
%! fprintf(fileID, testData);
%! fclose(fileID);
%!endfunction
%%
%% Mesh.import
%!     #1 Некорректный дескриптор файла
%!error <file not found>
%! Mesh.import('not_found.txt');
%%
%!test #2 Неизвестный формат файла
%! filename = setupTestData('test','.not_supported');
%!
%! fail("Mesh.import(filename)","Unsupported format: .not_supported");
%!
%! delete(filename);
%!
%% Тесты 4ekm
%!test #3.Корректная загрузка файла
%!
%! testData = sprintf('8 \n1 \n0.000000   0.000000   0.000000\n0.250000   0.000000   0.000000 \n0.500000   0.000000   0.000000\n0.750000   0.000000   0.000000\n1.000000   0.000000   0.000000\n0.000000   0.250000   0.000000\n   0.250000   0.250000   0.000000\n0.500000   0.250000   0.000000\n 1      2      3      4     5     6     7    8 ');
%! filename = setupTestData(testData,'.4ekm');
%!
%! grid = Mesh.import(filename);
%!
%! delete(filename);
%!
%! assert(isa(grid.nodes, 'double'));
%! assert(size(grid.nodes), [8, 3]);
%! assert(grid.nodes, [0 0 0; 0.25 0 0; 0.5 0 0; 0.75 0 0; 1 0 0; 0 0.25 0; 0.25 0.25 0; 0.5 0.25 0]);
%!
%! assert(isa(grid.elements.hexas, 'int32'));
%! assert(size(grid.elements.hexas), [1, 8]);
%! assert(grid.elements.hexas, int32([1 2 3 4 5 6 7 8]));
%!
%!test #4.Пустой файл
%! filename = setupTestData('', '.4ekm');
%!
%! fail("Mesh.import(filename)","unexpected EOF on line 1 of block header");
%!
%! delete(filename);
%!
%!test #5.Неполные данные узлов
%!
%! testData = sprintf('8 \n1 \n0.000000   0.000000 \n0.250000   0.000000   \n0.500000   0.000000 \n0.750000   0.000000 \n1.000000   0.000000   \n0.000000   0.250000 \n   0.250000   0.250000 \n0.500000   0.250000\n 1      2      3      4     5     6     7     8');
%! filename = setupTestData(testData,'.4ekm');
%!
%! fail("Mesh.import(filename)","expected 3 numbers, but 2 is read on line 1 of block nodes");
%!
%! delete(filename);
%!
%!test #6.Неполные данные элементов
%!
%! testData = sprintf('8 \n2 \n0.000000   0.000000   0.000000\n0.250000   0.000000   0.000000 \n0.500000   0.000000   0.000000\n0.750000   0.000000   0.000000\n1.000000   0.000000   0.000000\n0.000000   0.250000   0.000000\n   0.250000   0.250000   0.000000\n0.500000   0.250000   0.000000\n 1      2      3      4     5     6     7     8');
%! filename = setupTestData(testData, '.4ekm');
%!
%! fail("Mesh.import(filename)","unexpected EOF on line 2 of block hexas");
%!
%! delete(filename);
%!
%% Тесты romanov
%!test #7.Корректная загрузка файла
%!
%! testData = sprintf('8 \n1 \n1 0.000000   0.000000   0.000000\n2 0.250000   0.000000   0.000000 \n3 0.500000   0.000000   0.000000\n4 0.750000   0.000000   0.000000\n5 1.000000   0.000000   0.000000\n6 0.000000   0.250000   0.000000\n7  0.250000   0.250000   0.000000\n8 0.500000   0.250000   0.000000\n1  1      2      3      4     5     6     7    8 ');
%! filename = setupTestData(testData,'.romanov');
%!
%! grid = Mesh.import(filename);
%!
%! delete(filename);
%!
%! assert(isa(grid.nodes, 'double'));
%! assert(size(grid.nodes), [8, 3]);
%! assert(grid.nodes, [0 0 0; 0.25 0 0; 0.5 0 0; 0.75 0 0; 1 0 0; 0 0.25 0; 0.25 0.25 0; 0.5 0.25 0]);
%!
%! assert(isa(grid.elements.hexas, 'int32'));
%! assert(size(grid.elements.hexas), [1, 8]);
%! assert(grid.elements.hexas, int32([1 2 3 4 5 6 7 8]));
%%
%!test #8.Пустой файл
%! filename = setupTestData('', '.romanov');
%!
%! fail("Mesh.import(filename)","unexpected EOF on line 1 of block header");
%!
%! delete(filename);
%!
%!test #9.Неполные данные узлов
%!
%! testData = sprintf('8 \n1 \n1 0.000000   0.000000 \n2 0.250000   0.000000   \n3 0.500000   0.000000 \n4 0.750000   0.000000 \n5 1.000000   0.000000   \n6 0.000000   0.250000 \n7   0.250000   0.250000 \n8 0.500000   0.250000\n1 1      2      3      4     5     6     7     8');
%! filename = setupTestData(testData,'.romanov');
%!
%! fail("Mesh.import(filename)","expected 4 numbers, but 3 is read on line 1 of block nodes");
%!
%! delete(filename);
%!
%!test #10.Неполные данные элементов
%!
%! testData = sprintf('8 \n2 \n1 0.000000   0.000000   0.000000\n2 0.250000   0.000000   0.000000 \n3 0.500000   0.000000   0.000000\n4 0.750000   0.000000   0.000000\n5 1.000000   0.000000   0.000000\n6 0.000000   0.250000   0.000000\n7    0.250000   0.250000   0.000000\n8 0.500000   0.250000   0.000000\n 1 1      2      3      4     5     6     7     8');
%! filename = setupTestData(testData, '.romanov');
%!
%! fail("Mesh.import(filename)","unexpected EOF on line 2 of block hexas");
%!
%! delete(filename);
%!
