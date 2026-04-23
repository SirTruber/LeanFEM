% N  [numNodes x 1];
% dN [numNodes x paramDim];
% xi [paramDim x 1];
classdef C2D4M < C2D4
    properties
      param = 1
      quadrature = GaussQuadrature(2, 1)
    end
    methods
          function gamma = getHourglass(obj, nodeCoords)
            H = [ones(obj.numNodes,1), nodeCoords'];
            Q = orth(H);
            v = [1 -1 1 -1];
            gamma = v - v*(Q*Q');
        end
    end
end
