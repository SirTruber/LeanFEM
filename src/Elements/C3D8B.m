% C3D8_SRI.m
classdef C3D8B < C3D8
    properties
        quadVol
    end
    methods
        function obj = C3D8B()
            obj = obj@C3D8();
        end
        
        function Ke = computeStiffness(obj, problem, nodeCoords, material)
            volIndices = [1;2;3];
            
            D = problem.elasticityMatrix(material);
  
            V = 0;
            Bvol = 0;
            for ip = 1:obj.quadrature.nPoints
                xi = obj.quadrature.points(:, ip);
                w  = obj.quadrature.weights(ip);
                [grad, detJ] = obj.computeGradient(xi, nodeCoords);
                N = obj.shapeFunction(xi);
                B = problem.strainDisplacementMatrix(grad, N, nodeCoords);
                
                V = V + detJ * w;
                
                Bvol = Bvol + B(volIndices, :) * detJ * w;
            end

            Bvol = Bvol / V;
            
            % Девиаторная часть по полной квадратуре
            Ke = 0;
            for ip = 1:obj.quadrature.nPoints
                xi = obj.quadrature.points(:, ip);
                w  = obj.quadrature.weights(ip);
                [grad, detJ] = obj.computeGradient(xi, nodeCoords);
                N = obj.shapeFunction(xi);
                B = problem.strainDisplacementMatrix(grad, N, nodeCoords);
                B(volIndices,:) = Bvol;

                Ke = Ke + B' * D * B * detJ * w;
            end
        end
    end
end