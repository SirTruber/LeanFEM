classdef Context < handle
    properties
        %grid        % Сетка,            GridData
        regions     % Области расчёта,  containers.map region_id -> RegionData
        modules     % Модули,           containers.map module_id -> Module

%        data_deps   % Зависимости, данные -> модули
%        module_deps % Зависимости, модули -> данные

        results     % результаты, которые доступны всем модулям
    end

    methods
        function addRegion(obj, name, dimension, elements)
            new_region = RegionData();
            new_region.dimension = dimension;
            new_region.elements = elements;
            new_region.calculateNodes(obj.grid);
            obj.regions(name) = new_region;
        end

        function addModule(obj, name, module)
            obj.modules(name) = module;
            % Регистрация зависимостей "входные данные -> модуль"
%             inputs = module.INPUT_DATA;
%             for i = 1:length(inputs)
%                 if ~obj.data_deps.isKey(inputs{i})
%                     obj.data_deps(inputs{i}) = {};
%                 end
%                 obj.data_deps(inputs{i}) = [obj.data_deps(inputs{i}), module];
%             end
%
%             % Регистрация зависимостей "модуль -> выходные данные"
%             obj.module_deps(module_type) = module.OUTPUT_DATA;
        end

        function state = check_ready(obj, requested_input)
            input = intersect(requested_input, key(result),'stable');
            if isequal(input, requested_input)
                state = true;
            else
                state = false;
            end
        end

        function run(obj, module_name, region_name ,requested_output)
            modules(name).request(obj, requested_output);
        end
   end
end
