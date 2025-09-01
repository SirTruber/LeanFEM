classdef StaticResult < handle
    properties
        displacement
        stress
        strain
        vonMisesStress
        mesh
    end
    methods
        function result = StaticResult(mesh,element,U)
            U = reshape(U,3,[]);
            result.displacement = struct('ux',U(1,:)','uy',U(2,:)','uz',U(3,:)');

            [strain,stress] = evaluateStrainAndStress(element, mesh, U);

            result.stress = struct('sxx',stress(1,:)','syy',stress(2,:)','szz',stress(3,:)','sxy',stress(4,:)','syz',stress(5,:)','szx',stress(6,:)');
            result.strain = struct('exx',strain(1,:)','eyy',strain(2,:)','ezz',strain(3,:)','exy',strain(4,:)','eyz',strain(5,:)','ezx',strain(6,:)');
            result.vonMisesStress = evaluateVonMisesStress(stress);

            result.mesh = mesh;
        end
    end
end
