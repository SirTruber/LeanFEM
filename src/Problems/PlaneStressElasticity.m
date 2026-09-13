classdef PlaneStressElasticity < PlaneStrainElasticity
    properties
        thickness = 1.0   % толщина
    end

    methods
        function obj = PlaneStressElasticity(element, thickness)
            obj = obj@PlaneStrainElasticity(element);
            if nargin > 2, obj.thickness = thickness; end
        end

        function D = elasticityMatrix(obj, material)
            % Эффективные модули для плоского напряжения
            E = material.youngModule;
            nu = material.poissonRatio;
            Eef = E / (1 - nu^2);
            nuef = nu / (1 - nu);

            lambda = Eef * nuef / ((1 + nuef)*(1 - 2*nuef));
            mu = obj.material.secondLame;

            D = blkdiag(...
                lambda*ones(2) + 2*mu*eye(2), ...
                mu);
        end

        function factor = volumeFactor(obj, ~)
            factor = obj.thickness;
        end
    end
end
