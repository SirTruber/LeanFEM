classdef GridData < handle
    properties
        name    % Уникальный идентификатор (строка)
        nodes   % Координаты узлов сетки [Mx3]
        quads   % Четырехугольные элементы(генерируются автоматически) [Nx4]
        hexas   % Гексаэдральные элементы, [Kx8]
    end
    methods
        function quads_to_hexas = generateQuads(obj)
            a = [1 4 3 2; 5 6 7 8; 1 2 6 5; 4 8 7 3; 2 3 7 6; 4 1 5 8];

            obj.quads = reshape(obj.hexas(:,a),[],4); %Собираем все грани гексаэдров

            [u,ida,idx] = unique(sort(obj.quads,2),"rows"); %Оставляем только уникальные
            count = histc(idx,1:rows(u));

            obj.quads = obj.quads(ida(count == 1),:); % И которые встречаются только один раз

            quads_to_hexas = idivide(ida(count == 1) - 1,int16(6)) + 1;
        end

        function p = points(obj,ind)
            p = obj.nodes(obj.hexas(ind,:)',:);
        end

        function selected = select(obj, type, target)
            %selected   индексы объектов типа type, удовлетворяющих target
            %type -     выбор условия: 'nodes' - по координатам, 'quads' - по четырёхугольникам ,'hexas' - по гексаэдрам
            %target     функция-предикат, принимает массив координат соответствующего размера
            if ~isa(condition_value, 'function_handle')
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
