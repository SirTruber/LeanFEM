classdef MaterialDB < handle
    properties
        materials   %containers.Map char->struct набор материалов
    end
    methods
        function obj = MaterialDB()
            obj.materials = containers.Map('KeyType', 'char', 'ValueType', 'any');
            steel = struct('density', 7.8, 'young_module', 2.1,'poisson_ratio', 0.3);
%             ESP = struct('density',1.0e-11, 'young_module', 0.1,'poisson_ratio', 0.4);

            obj.add('steel',steel);
%             obj.add('ESP',ESP);
        end

        function add(obj, name, value)
            value.firstLame =  value.poisson_ratio * value.young_module / (1 - value.poisson_ratio * (1 + 2 * value.poisson_ratio));
            value.secondLame = 0.5 * value.young_module / (1 + value.poisson_ratio);
            value.waveSpeed = sqrt((value.firstLame + 2 * value.secondLame) / value.density);

            obj.materials(name) = value;
        end
    end
end
