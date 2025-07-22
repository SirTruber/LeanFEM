classdef  StaticSolver < Module
    properties (Constant)
        INPUT_DATA = {'K','dofs','F'}
        OUTPUT_DATA = {'U'}
    end
    methods
        function execute(obj, context)
            attach = context.results('dofs');
            K = context.results('K');
            K(attach,:) = 0;
            K(:,attach) = 0;
            K(sub2ind(size(K),attach,attach)) = 1;
            context.results('U') = context.results('K') / context.results('F');
        end
    end
end
