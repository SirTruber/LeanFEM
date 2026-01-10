classdef C3D8R < C3D8 % Схема Уилкинса. Стоит применять только для динамических задач
    methods
        function obj = C3D8R(material)
            obj@C3D8(material,1);
        end
    end
end
