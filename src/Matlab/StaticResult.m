classdef StaticResult < handle
    properties
        displacement
        stress
        strain
        vonMisesStress

        finiteElement
        mesh
    end
    methods
        function result = StaticResult(mesh,element,U)
            result.displacement = struct('ux',U(1:3:end,:),'uy',U(2:3:end,:),'uz',U(3:3:end,:));

            result.finiteElement = element;
            result.mesh = mesh;

            evaluateStrainAndStress(result);
            evaluateVonMisesStress(result);
        end
    end
end
