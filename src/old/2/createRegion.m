function region = createRegion(dim, elementsNumber, varargin)
% necessery properties:
%   Dimension, int
%   Elements, int[]
% optional properties:
%   Attach,enum X,Y,Z
%   Name, char[]
%   Load, function
%   Material, char[]
%   Scheme, char[]

    region = struct();

    region.Dimension = dim;
    region.Elements = elementsNumber;

    p = inputParser;

    addParameter(p, 'Attach','', @ischar );
    addParameter(p, 'Name'  ,'', @ischar );
    addParameter(p, 'Load',[], @(x) isempty(x) || isa(x, 'function_handle'));
    addParameter(p, 'Material','', @ischar );
    addParameter(p, 'Scheme','', @ischar );

    parse(p, varargin{:});

    if ~isempty(p.Results.Name)
        region.Name = p.Results.Name;
    endif

    check = 'XYZ';

    attach = ismember(check,upper(p.Results.Attach));
    if any(attach ~= 0)
        region.Attach = attach;
    endif

    cd Material;
    switch p.Results.Material
        case 'Steel'
            region.Material = Steel;
        case 'ESP'
            region.Material = ESP;
    endswitch
    cd ../
    if isfield(region, 'Material')
        cd Element
        switch p.Results.Scheme
            case 'Moment'
                region.FiniteElement = HM24(region.Material);
            case 'Rare'
                region.FiniteElement = TL12(region.Material);
            case 'SuperRare'
                region.FiniteElement = TL12(region.Material);
        endswitch
        region.Scheme = p.Results.Scheme;
        cd ../
    endif

    if ~isempty(p.Results.Load)
        region.Load = p.Results.Load;
    endif
endfunction
