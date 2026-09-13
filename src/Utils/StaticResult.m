classdef StaticResult < handle
    properties
        displacement
        stress
        strain
        vonMises

        asm
    end
    methods
        function result = StaticResult(asm,U)
            result.displacement = reshape(U,3,[]);%struct('ux',U(1:3:end,:),'uy',U(2:3:end,:),'uz',U(3:3:end,:));

            result.asm = asm;
            result.stress = asm.nodalStress(result.displacement);
            result.strain = asm.nodalStrain(result.displacement);
            result.vonMises = asm.problem.vonMises(result.stress);
        end
    end
end
