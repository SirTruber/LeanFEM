classdef DynamicResult < handle
    properties
        timeHistory
        displacement

        asm
    end
    methods
        function result = DynamicResult(asm,t,U)
            result.displacement = reshape(U,3,asm.mesh.numNodes(),numel(t));%struct('ux',U(1:3:end,:),'uy',U(2:3:end,:),'uz',U(3:3:end,:));
            result.timeHistory = t;
            result.asm = asm;
        end

        function ret = stress(obj,i)
            U = squeeze(obj.displacement(:,:,i));
            ret = obj.asm.nodalStress(U);
        end

        function ret = strain(obj,i)
            U = squeeze(obj.displacement(:,:,i));
            ret = obj.asm.nodalStrain(U);
        end

        function ret = vonMises(obj,i)
            U = squeeze(obj.displacement(:,:,i));
            S = obj.asm.nodalStress(U);
            ret = obj.asm.problem.vonMises(S);
        end
    end
end
