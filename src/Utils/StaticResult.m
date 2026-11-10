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
            result.displacement = reshape(U,asm.problem.dofPerNode,[]);

            result.asm = asm;
            result.stress = asm.nodalStress(result.displacement);
            result.strain = asm.nodalStrain(result.displacement);
            result.vonMises = asm.problem.vonMises(result.stress);
        end
    end
end
