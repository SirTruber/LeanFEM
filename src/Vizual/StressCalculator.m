classdef StressCalculator < handle
    properties
        CB
        mask
    end
    methods
        function obj = StressCalculator(grid,elem,ind)
            B_cell = arrayfun(@(i) elem.elasticity * elem.grad(grid.points(i)),ind,'UniformOutput',false);
            obj.CB = cell2mat(B_cell);
            disp(size(B_cell{1}));
            disp(size(obj.CB));
            mask = grid.hexas(ind,:);
            mask = 3 * repelem(mask,1,3) - repmat([2 1 0], numel(ind), 8);
            obj.mask = mask.'(:);
        end

        function stress = Tensor(obj,U)
            stress = obj.CB * U(obj.mask);
        end
        function stress = VonMises(obj,U)
            S = obj.Tensor(U);
            stress = zeros(1,size(S,2));
            for i = 1:size(S,2)
                stress(i) = 1/sqrt(2) * sqrt((S(1,i) - S(2,i))^2 + (S(2,i) - S(3,i))^2 + (S(3,i) - S(1,i))^2 + 6*(S(4,i)^2 + S(5,i)^2 + S(6,i)^2));
            end
        end
    end
end
