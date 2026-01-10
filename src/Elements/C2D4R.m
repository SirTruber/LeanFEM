classdef C2D4R < C2D4 % Схема Уилкинса. Стоит применять только для динамических задач
    methods
        function obj = C2D4R(material)
            obj@C2D4(material,1);
        end
    end
end
