classdef PlaneStressElasticity < PlaneStrainElasticity
    properties
        thickness = 1.0   % толщина
    end

    methods
        function obj = PlaneStressElasticity(element, material, thickness)
            obj = obj@PlaneStrainElasticity(element, material);
            if nargin > 3, obj.thickness = thickness; end
        end

        function D = elasticityMatrix(obj)
            % Эффективные модули для плоского напряжения
            E = obj.material.youngModule;
            nu = obj.material.poissonRatio;
            Eef = E / (1 - nu^2);
            nuef = nu / (1 - nu);

            lambda = Eef * nuef / ((1 + nuef)*(1 - 2*nuef));
            mu = Eef / (2*(1 + nuef));

            D = blkdiag(...
                lambda*ones(2) + 2*mu*eye(2), ...
                mu);
        end

        function factor = volumeFactor(obj, ~)
            factor = obj.thickness;
        end
    end
end
