function problem = createProblem(grid, varargin)
    problem = struct();

    problem.attach = computeAttach(grid);

    p = inputParser;

    addParameter(p, 'Dynamic'  , false, @isboolean );
    addParameter(p, 'Damping'  , false, @isboolean );
    addParameter(p, 'Kurant' , 1, @isnumeric);

    problem.attach = computeAttach(grid);
    problem.load = computeLoad(grid);

    parse(p, varargin{:});
    if ~p.Results.Dynamic
        problem.stiffness = globalCompute(grid);
    elseif ~p.Results.Damping
        [problem.stiffness,problem.mass] = globalCompute(grid);
    else
        [problem.stiffness,problem.mass,problem.damping] = globalCompute(grid);
    end

    problem.time_step = p.Results.Kurant * CFL(grid);
endfunction

function attach = computeAttach(grid)
    attach = [];
    for r = 1:rows(grid.regions)
        reg = grid.regions{r};
        if isfield(reg, 'Attach')
            at = [];
            switch reg.Dimension
                case 0
                    at = reg.Elements;
                case 2
                    at = grid.quads(reg.Elements)(:);
                case 3
                    at = grid.hexas(reg.Elements)(:);
            endswitch

            at = 3 * unique(at);
            for i = 1:3
                if reg.Attach(i)
                    attach = [attach; at-(3-i)];
                endif
            endfor
        endif
    endfor
    attach = unique(attach);
endfunction


function [K,M,D] = globalCompute(grid)
    n = rows(grid.hexas);
    m = 3 * rows(grid.nodes);
    switch nargout
        case 0
            return;
        case 1
            K = sparse([],[],[],m,m);
        case 2
            K = sparse([],[],[],m,m);
            M = sparse([],[],[],m,m);
        case 3
            K = sparse([],[],[],m,m);
            M = sparse([],[],[],m,m);
            D = sparse([],[],[],m,m);
    endswitch
    for r = 1:rows(grid.regions)
        reg = grid.regions{r};
        if reg.Dimension == 3 && isfield(reg, 'FiniteElement')
            ij_trip = repelem(3*grid.hexas(reg.Elements,:)'(:),3) + repmat(int32(-2:0),1,n*8)';
            i_trip = repelem(reshape(ij_trip,24,[]),1,24)(:);
            j_trip = repelem(ij_trip,24);
            switch nargout
                case 1
                stiffness = arrayfun(@(i) reg.FiniteElement.compute(grid.points(i)),reg.Elements,'UniformOutput',false);
                stiffness = cell2mat(stiffness);
                K += sparse(i_trip,j_trip,stiffness.'(:),m,m);
                case 2
                [stiffness,mass] = arrayfun(@(i) reg.FiniteElement.compute(grid.points(i)),reg.Elements,'UniformOutput',false);
                stiffness = cell2mat(stiffness);
                mass = cell2mat(mass);
                K += sparse(i_trip,j_trip,stiffness.'(:),m,m);
                M += sparse(i_trip,j_trip,mass(:),m,m);
                case 3
                [stiffness,mass,damping] = arrayfun(@(i) reg.FiniteElement.compute(grid.points(i)),reg.Elements,'UniformOutput',false);
                stiffness = cell2mat(stiffness);
                mass = cell2mat(mass);
                damping = cell2mat(damping)
                K += sparse(i_trip,j_trip,stiffness.'(:),m,m);
                M += sparse(i_trip,j_trip,mass(:),m,m);
                D += sparse(i_trip,j_trip,damping(:),m,m);
            endswitch
        endif
    endfor
endfunction

function time_step = CFL(grid)
    tmp = [];
    for r = 1:rows(grid.region)
        reg = grid.region{r};
        if reg.Dimension == 3 && isfield(reg, 'Material')
            tmp = [tmp grid.minHeight(reg.Elements)/reg.Material.waveSpeed];
        endif
    endfor
    time_step = min(tmp);
endfunction

function load = computeLoad(grid)
    load = zeros(size(grid.nodes));
    for r = 1:rows(grid.regions)
        reg = grid.regions{r};
        if isfield(reg, 'Load')
%             load() = arrayfun(@(i) reg.Load(grid.points(i)),reg.Elements,'UniformOutput',false);
        endif
    endfor
endfunction
