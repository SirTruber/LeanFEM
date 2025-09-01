classdef Model < handle
    properties
        analysisType = 'static'
        geometry
        regions

        faceBC
        edgeBC
        vertexBC

        cellLoad
        faceLoad
        edgeLoad
        vertexLoad

        cellIC
        faceIC
        edgeIC
        vertexIC

        load
        bc
    end
    methods
        function this = Model(geometry)
            this.geometry = geometry;
            this.load = zeros(3,geometry.numVertices);
        end

        function addPressure(this,ind,value)
            mesh = this.geometry.mesh;
            n = numel(ind);
            faces = mesh.generateQuads()(:,ind);

            nodes = mesh.nodes(:,faces);

            A = nodes(:,1:4:end);
            B = nodes(:,2:4:end);
            C = nodes(:,3:4:end);
            D = nodes(:,4:4:end);

            v1 = B - A;
            v2 = C - A;
            v3 = D - A;

            normals = 0.5 * (cross(v1,v2) + cross(v1,v3));
            forces = value * normals / 4;
            for i = 1:n
                this.load(:,faces(:,i)) = this.load(:,faces(:,i)) + forces(:,i);
            end
        end

        function region = addRegion(obj,elemID,feSpace)
        end

        function varargout = subsref(obj, S)
            if numel(S) >= 1 && strcmp(S(1).type, '()') && strcmp(S(1).subs{1}, 'FaceLoad')
                % Обработка model.FaceLoad(FaceID)
                if numel(S) > 1 && strcmp(S(2).type, '=')
                    % Присваивание: model.FaceLoad(FaceID) = value
                    obj.setFaceLoad(S(1).subs{2:end}, S(2).subs{1});
                else
                    % Чтение: value = model.FaceLoad(FaceID)
                    [varargout{1:nargout}] = obj.getFaceLoad(S(1).subs{2:end});
                end
            else
                % Стандартная обработка для других случаев
                [varargout{1:nargout}] = builtin('subsref', obj, S);
            end
        end

        function varargout = subsassign(obj, S)
            if numel(S) >= 1 && strcmp(S(1).type, '()') && strcmp(S(1).subs{1}, 'FaceLoad')
                % Обработка model.FaceLoad(FaceID)
                if numel(S) > 1 && strcmp(S(2).type, '=')
                    % Присваивание: model.FaceLoad(FaceID) = value
                    obj.setFaceLoad(S(1).subs{2:end}, S(2).subs{1});
                else
                    % Чтение: value = model.FaceLoad(FaceID)
                    [varargout{1:nargout}] = obj.getFaceLoad(S(1).subs{2:end});
                end
            else
                % Стандартная обработка для других случаев
                [varargout{1:nargout}] = builtin('subsref', obj, S);
            end
        end
        function result = isValidField(fieldName)
            specialField = {"faceBC", "edgeBC", "vertexBC", ...
                            "cellLoad", "faceLoad", "edgeLoad", "vertexLoad", ...
                            "cellIC", "faceIC", "edgeIC", "vertexIC"};
        end
        function disp(obj)
            fprintf('  Model object\n\n');
            fprintf('Properties for %s analysis:\n\n',obj.analysisType);
            if ~isempty(obj.geometry)
                obj.dispGeometry;
            end
        end

        function dispGeometry(obj)
            geom = obj.geometry;
            fprintf('geometry [%d;%d;%d;%d] \n\n',geom.numCells, geom.numFaces, geom.numEdges, geom.numVertices);
            fprintf('Boundary Conditions\n');
            fprintf('       FaceBC:[%dx%d faceBC]\n',numel(obj.faceBC), geom.numFaces);
            fprintf('       EdgeBC:[%dx%d edgeBC]\n',numel(obj.edgeBC), geom.numEdges);
            fprintf('     VertexBC:[%dx%d vertexBC]\n',numel(obj.vertexBC), geom.numVertices);
            fprintf('\n');
            fprintf('Loads\n');
            fprintf('     CellLoad:[%dx%d cellLoad]\n',numel(obj.cellLoad), geom.numCells);
            fprintf('     FaceLoad:[%dx%d faceLoad]\n',numel(obj.faceLoad), geom.numFaces);
            fprintf('     EdgeLoad:[%dx%d edgeLoad]\n',numel(obj.edgeLoad), geom.numEdges);
            fprintf('   VertexLoad:[%dx%d vertexLoad]\n',numel(obj.vertexLoad), geom.numVertices);
            fprintf('\n');
            if strcmp(obj.analysisType,'dynamic')
            fprintf('Initial Conditions\n');
            fprintf('       CellIC:[%dx%d cellIC]\n',numel(obj.cellIC), geom.numCells);
            fprintf('       FaceIC:[%dx%d faceIC]\n',numel(obj.faceIC), geom.numFaces);
            fprintf('       EdgeIC:[%dx%d edgeIC]\n',numel(obj.edgeIC), geom.numEdges);
            fprintf('     VertexIC:[%dx%d vertexIC]\n',numel(obj.vertexIC), geom.numVertices);
            fprintf('\n');
            end
        end

        function result = solve(obj, regionID)
        end

        function changeTask(obj)
            if strcmp(obj.analysisType,'static')
                obj.analysisType = 'dynamic';
            else
                obj.analysisType = 'static';
            end
        end

        function h = plot(obj, varargin)
            h = obj.geometry.plot(varargin);
        end

        function h = plotMesh(obj, varargin)
            h = obj.geometry.plotMesh(varargin);
        end
    end
end

%!test #создание модели по готовой геометрии
%!
%!test #создание пустой модели с добавлением геометрии впоследствии
%!
%!test #добавление региона с моментными элементами
%!
%!test #добавление региона с ажурными элементами
%!
%!test #добавление региона с несуществующим типом элемента
%!
%!test #добавление региона с несуществующими узлами
%!
%!test #добавление региона с дублирующимися элементами
%!
%!test #добавление граничных условий на ячейку
%!
%!test #добавление граничных условий на грань
%!
%!test #добавление граничных условий на вершину
%
%!test #добавление граничных условий к несуществующим элементам
%!
%!test #удаление граничных условий
%!
%!test #добавление гравитации на ячейку
%!
%!test #добавление давления на грань
%!
%!test #добавление сил на вершину
%!
%!test #добавление нагрузок к несуществующим элементам
%!
%!test #смена типа задачи
%!
%! model = Model;
%! assert(model.analysisType,'static');
%! model.changeTask;
%! assert(model.analysisType,'dynamic');
%! model.changeTask;
%! assert(model.analysisType,'static');
%!
%!test #решение статической задачи с одним регионом
%!
%!test #решение динамической задачи с одним регионом
%!
%!test #решение статической задачи с несколькими регионами
%!
%!test #решение динамической задачи с несколькими регионами
%!
%!test #запуск решателя с неполной информацией
