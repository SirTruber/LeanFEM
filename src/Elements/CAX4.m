% N  [numNodes x 1];
% dN [numNodes x paramDim];
% xi [paramDim x 1];
classdef CAX4 < C2D4
    methods
        function val = integrate(obj,nodeCoords,func)
            val = 0;

            for ip = 1:obj.quadrature.nPoints
                xi = obj.quadrature.points(:, ip);
                w = obj.quadrature.weights(ip);

                [grad, detJ] = obj.computeGradient(xi, nodeCoords);
                N = obj.shapeFunction(xi);
                r = nodeCoords(1,:) * N;

                val = val + 2 * pi * func(xi,grad,detJ,N) * detJ * w * r;
            end
        end
    end
end
