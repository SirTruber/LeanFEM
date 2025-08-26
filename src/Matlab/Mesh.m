classdef Mesh < handle
    properties
        nodes
        hexas
    end
    methods (Static)
        function geom = import(filename)
            if nargin == 0
                error('file not found');
            end
            unwind_protect
                fileID = fopen(filename,"r");
                if ~is_valid_file_id(fileID)
                    error('file not found');
                end

                [~, ~, ext] = fileparts(filename);
                loader = getLoader(ext);
                mesh = loader(fileID);
            unwind_protect_cleanup
                if fileID ~= -1
                    fclose(fileID);
                end
            end_unwind_protect
            geom = Geometry(mesh);
        end
    end
    methods
        function obj = Mesh(nodes, hexas)
            if nargin < 1
                nodes = zeros(3,0);
            end
            if nargin < 2
                hexas = zeros(8,0,'int32');
            end

            validateattributes(nodes,{'numeric'}, {'nrows', 3, 'real', 'finite'});
            numNodes = size(nodes,2);
            validateattributes(hexas, {'integer'}, {'nrows',8,'positive','<=',numNodes});

            obj.nodes = nodes;
            obj.hexas = hexas;
        end

        function elemID = findElements(mesh,findType,arg1,arg2)
        end

        function nodeID = findNodes(mesh,findType,arg1,arg2)
        end

        function coord = points(mesh, elemID)
            coord = mesh.nodes(:,mesh.hexas(:,elemID));
        end

        function validate(mesh)
        end
    end
end


function loader = getLoader(ext)
    switch lower(ext)
        case '.4ekm'
            loader = @parse4ekm;
        case '.romanov'
            loader = @parseRomanov;
        otherwise
            error('Unsupported format: %s', ext);
    end
end

function mesh = parse4ekm(fileID)
    headerSize = [2;1];
    nodesDim = 3;
    elementDim = 8;
    try
        header = parseDataBlock(fileID, headerSize(1), headerSize(2),'int');
        numberOfNodes = header(1);
        numberOfHexas = header(2);
    catch err
        error('%s of block header', err.message);
    end
    try
        nodes = parseDataBlock(fileID, numberOfNodes, nodesDim, 'double');
    catch err
        error('%s of block nodes', err.message);
    end
    try
        hexas = parseDataBlock(fileID, numberOfHexas, elementDim, 'int'); % Нет проверки, все ли узлы существуют, ответственность билдера
    catch err
        error('%s of block hexas', err.message);
    end

    mesh = Mesh(nodes',hexas');
end

function write4ekm(fileID, mesh)
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

function mesh = parseRomanov(fileID)
    headerSize = [2;1];
    nodesDim = 3;
    elementDim = 8;
    try
        header = parseDataBlock(fileID, headerSize(1), headerSize(2),'int');
        numberOfNodes = header(1);
        numberOfHexas = header(2);
    catch err
        error('%s of block header', err.message);
    end
    try
        nodes = parseDataBlock(fileID, numberOfNodes, 1 + nodesDim, 'double')(:,2:end);
    catch err
        error('%s of block nodes', err.message);
    end
    try
        hexas = parseDataBlock(fileID, numberOfHexas, 1 + elementDim, 'int')(:,2:end); % Нет проверки, все ли узлы существуют, ответственность билдера
    catch err
        error('%s of block hexas', err.message);
    end

    mesh = Mesh(nodes',hexas');
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

%!function mesh = testMesh()
%!  nodes = [0 1 1 0 0 1 1 0; 0 0 1 1 0 0 1 1;0 0 0 0 1 1 1 1];
%!  hexas = int32([1;2;3;4;5;6;7;8]);
%!  mesh = Mesh(nodes, hexas);
%!endfunction
%!
%!function filename = setupTestData(testData, format)
%! filename = [tempname(), format];
%! fileID = fopen(filename, 'w');
%! fprintf(fileID, testData);
%! fclose(fileID);
%!endfunction
%%
%% Mesh.import
%!     #Некорректный дескриптор файла
%!error <file not found>
%! Mesh.import('not_found.txt');
%!
%!     #Некорректный дескриптор файла
%!error <file not found>
%! Mesh.import;
%!
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
%! assert(grid.numCells, 1);
%! assert(grid.numFaces, 6);
%! assert(grid.numEdges, 12);
%! assert(grid.numVertices, 8);
%!
%! assert(isa(grid.vertices, 'double'));
%! assert(isa(grid.edges, 'int32'));
%! assert(isa(grid.faces, 'int32'));
%! assert(isa(grid.mesh, 'Mesh'));
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
%! assert(grid.numCells, 1);
%! assert(grid.numFaces, 6);
%! assert(grid.numEdges, 12);
%! assert(grid.numVertices, 8);
%!
%! assert(isa(grid.vertices, 'double'));
%! assert(isa(grid.edges, 'int32'));
%! assert(isa(grid.faces, 'int32'));
%! assert(isa(grid.mesh, 'Mesh'));
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
%!test  #создание пустого меша
%!
%! mesh = Mesh;
%!
%! assert(isempty(mesh.nodes));
%! assert(isempty(mesh.hexas));
%!
%!test  #создание заполненного меша
%!
%! mesh = testMesh();
%!
%! assert(mesh.nodes,[0 1 1 0 0 1 1 0; 0 0 1 1 0 0 1 1; 0 0 0 0 1 1 1 1]);
%! assert(mesh.hexas,int32([1;2;3;4;5;6;7;8]));
%!
%!      #создание меша с неправильным размером узлов
%!error<input must have 3 rows> Mesh([1 2 3 4 5 6]);
%!
%!      #создание меша с неправильным размером элементов
%!error<input must have 8 rows> Mesh([1;2;3],int32([1; 2; 3; 4; 5; 6]));
%!
%!      #создание меша с некоректным типом данных
%!fail("Mesh('string')");
%!
%!xtest  #поиск элементов по ID
%!
%!xtest  #поиск элементов в box
%!
%!xtest  #поиск элементов в радиусе
%!
%!xtest  #поиск элементов, которые прикреплены к определённым узлам
%!
%!xtest   #поиск элементов по предикату
%!
%!xtest  #поиск элементов по неправильному условию
%!
%!xtest  #поиск узлов по ID
%!
%!xtest  #поиск узлов в box
%!
%!xtest  #поиск узлов в радиусе
%!
%!xtest  #поиск узлов, ближайших к точке
%!
%!xtest  #поиск узлов по предикату
%!
%!xtest  #поиск узлов по неправильному условию
%!
%!xtest  #согласованность поиска по разным функциям
%!
%!xtest  #поиск в пустой сетке
%!
%!xtest  #поиск в сетке с одним элементом
%!
%!xtest  #неправильное число аргументов
%!
%!xtest  #поиск с некоректными аргументами
%!
