% C3D8_SRI.m
classdef C3D8SRI < C3D8
    properties
        quadVol
    end
    methods
        function obj = C3D8SRI()
            obj = obj@C3D8();
            obj.quadVol = GaussQuadrature(3, 1);
        end
        
        function Ke = computeStiffness(obj, problem, nodeCoords, material)
            volIndices = [1;2;3];
            
            D = problem.elasticityMatrix(material);
            lambda = material.firstLame;
            mu = material.secondLame;
            K = lambda + 2/3*mu; % модуль объёмного сжатия
            m = zeros(problem.strainSize, 1);
            m(volIndices) = 1;
            D_vol = K * (m * m');
            D_dev = D - D_vol;
  
            % Объёмна часть по сокращённой квадратуре
            Ke_vol = 0;
            for ip = 1:obj.quadVol.nPoints
                xi = obj.quadVol.points(:, ip);
                w  = obj.quadVol.weights(ip);
                [grad, detJ] = obj.computeGradient(xi, nodeCoords);
                N = obj.shapeFunction(xi);
                B = problem.strainDisplacementMatrix(grad, N, nodeCoords);

                Ke_vol = Ke_vol + B' * D_vol * B * detJ * w;
            end
            
            % Девиаторная часть по полной квадратуре
            Ke_dev = 0;
            for ip = 1:obj.quadrature.nPoints
                xi = obj.quadrature.points(:, ip);
                w  = obj.quadrature.weights(ip);
                [grad, detJ] = obj.computeGradient(xi, nodeCoords);
                N = obj.shapeFunction(xi);
                B = problem.strainDisplacementMatrix(grad, N, nodeCoords);

                Ke_dev = Ke_dev + B' * D_dev * B * detJ * w;
            end
            
            Ke = Ke_vol + Ke_dev;
        end
    end
end