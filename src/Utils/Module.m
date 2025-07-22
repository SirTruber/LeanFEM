classdef Module < handle
    properties (Abstract, Constant)
        INPUT_DATA  % Требуемые входные данные (cell array строк)
        OUTPUT_DATA % Все выходные данные (cell array строк)
    end
    properties
        active_output   % Требуемые выходные данные (cell array строк)
    end

    methods (Abstract)
        execute(obj,context) % Основная логика модуля
    end

    methods
        function request(obj, context, requested_output)
            obj.active_output = intersect(requested_output, obj.OUTPUT_DATA,'stable');
            if ~isempty(obj.active_output)
                return
            end
            if context.check_ready(obj.INPUT_DATA)
                obj.execute(context);
            end
        end
    end
end
