classdef Geometry < handle
    properties
        numCells
        numFaces
        numEdges
        numVertices

        vertices
        edges
        faces

        mesh
    end
    methods
        function obj = Geometry(mesh)
            obj.mesh = mesh;

            obj.vertices = mesh.nodes';
            obj.faces = generateQuads(mesh.hexas); % плейсхолдер, добавить сглаживатель и сшиватель сетки
            obj.edges = generateEdges(obj.faces);

            obj.numCells = size(mesh.hexas,2);
            obj.numFaces = size(obj.faces,2);
            obj.numEdges = size(obj.edges,2);
            obj.numVertices = size(mesh.nodes,2);
        end

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

        function geom3 = union(geom1, geom2)
        end

        function geom3 = substruct(geom1, geom2)
        end

        function geom3 = intersect(geom1,geom2)
        end

        function faceID = cellFaces(geom, elemID)
        end

        function edgeID = cellEdges(geom, elemID)
        end

        function nodesID = cellNodes(geom, elemID)
        end

        function cellID = faceCells(geom, elemID)
        end

        function edgeID = faceEdges(geom, elemID)
        end

        function nodesID = faceNodes(geom, elemID)
        end

        function faceID = edgeFaces(geom, elemID)
        end

        function cellID = edgeCells(geom, elemID)
        end

        function nodesID = edgeNodes(geom, elemID)
        end

        function rotate(obj, angle, refpoint1, refpoint2)
        end

        function scale(obj, scaleFactor, refpoint)
        end

        function translate(obj, distance)
        end

        function h = plot(obj, varargin)
        end

        function h = plotMesh(obj, varargin)
            figHandle = figure('Units', 'pixels', 'Position', [100, 100, 1200, 800]);

            faces = generateQuads(obj.mesh.hexas);
            h = patch('Faces', faces', 'Vertices', obj.mesh.nodes', 'FaceColor', 'c', 'EdgeColor', 'k');
            axis equal;

%             center = sum(obj.vertices,2)/size(obj.vertices,2);
%             elemText = [repelem('E',obj.numVertices,1),num2str((1:obj.numVertices)')];
%             for i = 1:obj.numVertices
%                 text(obj.vertices(i,1),obj.vertices(i,2),obj.vertices(i,3),sprintf('E%d',i));
%             end
        end
    end
end

function quads = generateQuads(hexas)
            a = int32( ...
           [1 2 3 4;...  % Грань 1 (нижняя)
            5 8 7 6;...  % Грань 2 (верхняя)
            1 5 6 2;...  % Грань 3 (передняя)
            4 3 7 8;...  % Грань 4 (задняя)
            2 6 7 3;...  % Грань 5 (правая)
            1 4 8 5]);    % Грань 6 (левая)

            quads = reshape(hexas(a',:),4,[]); %Собираем все грани гексаэдров

            [~,ida,idx] = unique(sort(quads)',"rows","stable"); %Оставляем только уникальные
            count = accumarray(idx,1);

            quads = quads(:,ida(count == 1)); % И которые встречаются только один раз
        end

        function edges = generateEdges(faces)
            a = int32(...
           [1 2;...  % Ребро 1 (нижнее)
            2 3;...  % Ребро 2 (правое)
            3 4;...  % Ребро 3 (верхнее)
            4 1]);    % Ребро 4 (левое)

            edges = reshape(faces(a',:),2,[]); %Собираем все ребра граней

            [~,ida,idx] = unique(sort(edges)',"rows","stable"); %Оставляем только уникальные
            count = accumarray(idx,1);

            edges = edges(:,ida(count == 1)); % И которые встречаются только один раз
        end
%!function mesh = testCube
%! [x,y,z] = meshgrid(0:1,0:1,0:1);
%! mesh = Mesh([x(:),y(:),z(:)]',int32([1;2;3;4;5;6;7;8]));
%!endfunction
%!test #создание геометрии с корректным Mesh
%!
%! grid = Geometry(testCube());
%!
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
%!test #создание геометрии с пустым Mesh
%!
%! grid = Geometry(Mesh);
%!
%! assert(grid.numCells, 0);
%! assert(grid.numFaces, 0);
%! assert(grid.numEdges, 0);
%! assert(grid.numVertices, 0);
%!
%! assert(isa(grid.vertices, 'double'));
%! assert(isa(grid.edges, 'int32'));
%! assert(isa(grid.faces, 'int32'));
%! assert(isa(grid.mesh, 'Mesh'));
%!
%!test #генерация граней для одного куба
%!
%! grid = Geometry(testCube());
%!
%! assert(grid.faces, int32([1 2 3 4; 5 8 7 6; 1 5 6 2; 4 3 7 8; 2 6 7 3; 1 4 8 5]'));
%!
%!test #генерация граней для восьми кубов
%!
%! [x,y,z] = meshgrid(-1:1,-1:1,-1:1);
%! mesh = Mesh([x(:),y(:),z(:)]',int32([1 2 4 5 10 11 13 14; 4 5 7 8 13 14 16 17; 5 6 8 9 14 15 17 18; 2 3 5 6 11 12 14 15; 10 11 13 14 19 20 22 23; 13 14 16 17 22 23 25 26; 14 15 17 18 23 24 26 27; 11 12 14 15 20 21 23 24]));
%! grid = Geometry(mesh);
%!
%! assert(grid.numFaces, 24);
%!endfunction
%!
%!test #генерация ребер для одного куба
%!
%!test #генерация ребер для восьми кубов
%!
%!test #объединение двух геометрий
%!
%!test #вычитание двух геометрий
%!
%!test #пересечение двух геометрий
%!
%!test #грани ячейки
%!
%!test #ребра ячейки
%!
%!test #узлы ячейки
%!
%!test #ребра граней
%!
%!test #узлы граней
%!
%!test #узлы ребер
%!
%!test #вращение вокруг оси OZ
%!
%!test #вращение вокруг произвольной оси
%!
%!test #масштабирование геометрии
%!
%!test #перенос геометрии
%!
%!test #набор последовательных преобразований
%!
