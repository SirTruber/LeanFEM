classdef SolidElasticity < AbstractProblem
    properties
        physicalDim = 3 % x, y, z
        dofPerNode = 3  % u, v, w
        strainSize = 6  % εxx, εyy, εzz, γxy, γyz, γxz
    end
    methods
        function obj = SolidElasticity(element)
            obj = obj@AbstractProblem(element);
        end

        function D = elasticityMatrix(obj, material)
            lambda = material.firstLame;
            mu = material.secondLame;
            D = blkdiag(...
                lambda*ones(3) + 2*mu*eye(3), ...
                mu*eye(3));
        end

        function B = strainDisplacementMatrix(obj, grad, ~, ~)
            numNodes = obj.element.numNodes;
            p = obj.dofPerNode;
            B = zeros(obj.strainSize, p*numNodes);

            B(1,1:p:end) = grad(1,:);                           %εxx
            B(2,2:p:end) = grad(2,:);                           %εyy
            B(3,3:p:end) = grad(3,:);                           %εzz
            B(4,1:p:end) = grad(2,:); B(4,2:p:end) = grad(1,:); %γxy
            B(5,2:p:end) = grad(3,:); B(5,3:p:end) = grad(2,:); %γyz
            B(6,1:p:end) = grad(3,:); B(6,3:p:end) = grad(1,:); %γxz
        end

        function G = gradientDisplacementMatrix(obj, grad, ~, ~) 
            numNodes = obj.element.numNodes;
            p = obj.dofPerNode;
            G = zeros(p*p, p*numNodes);
            
            G(1, 1:p:end) = grad(1,:);  % u_x,x
            G(2, 1:p:end) = grad(2,:);  % u_x,y
            G(3, 1:p:end) = grad(3,:);  % u_x,z
            G(4, 2:p:end) = grad(1,:);  % u_y,x
            G(5, 2:p:end) = grad(2,:);  % u_y,y
            G(6, 2:p:end) = grad(3,:);  % u_y,z
            G(7, 3:p:end) = grad(1,:);  % u_z,x
            G(8, 3:p:end) = grad(2,:);  % u_z,y
            G(9, 3:p:end) = grad(3,:);  % u_z,z
        end

        function vm = vonMises(obj, stress)
            sxx = stress(1,:); syy = stress(2,:); szz = stress(3,:);
            sxy = stress(4,:); syz = stress(5,:); sxz = stress(6,:);
            vm = sqrt(0.5*((sxx-syy).^2 + (syy-szz).^2 + (szz-sxx).^2 + 6*(sxy.^2+syz.^2+sxz.^2)));
        end
    end
end
