classdef C3D8 < Elasticity3D
    properties
        numNODE = 8
        numDOF = 24
    end
    methods
        function obj = C3D8(material,nquad)
            if nargin == 1
                nquad = 2;
            end
            obj = obj@Elasticity3D(material,nquad)
        end

        function N = shapeFunction(obj,xi) %TODO
            error('No impl yet') 
        end

        function dN = shapeGradient(obj,xi)
            dN = 0.125 * [(1-xi(2))*(1-xi(3)) (1+xi(2))*(1-xi(3)) -(1+xi(2))*(1-xi(3)) -(1-xi(2))*(1-xi(3))... 
                              (1-xi(2))*(1+xi(3))  (1+xi(2))*(1+xi(3)) -(1+xi(2))*(1+xi(3)) -(1-xi(2))*(1+xi(3));....                                                        
                             -(1+xi(1))*(1-xi(3))  (1+xi(1))*(1-xi(3)) (1-xi(1))*(1-xi(3))  -(1-xi(1))*(1-xi(3))... 
                             -(1+xi(1))*(1+xi(3))  (1+xi(1))*(1+xi(3)) (1-xi(1))*(1+xi(3))  -(1-xi(1))*(1+xi(3));...
                             -(1+xi(1))*(1-xi(2)) -(1+xi(1))*(1+xi(2))  -(1-xi(1))*(1+xi(2))   -(1-xi(1))*(1-xi(2))...   
                              (1+xi(1))*(1-xi(2))  (1+xi(1))*(1+xi(2))   (1-xi(1))*(1+xi(2))  (1-xi(1))*(1-xi(2))]';   
        end
    end
end
