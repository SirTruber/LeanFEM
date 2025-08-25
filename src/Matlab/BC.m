classdef BC < handle
    properties
        constraint = 'free'
        xDisplacement
        yDisplacement
        zDisplacement
    end
    methods
        function obj = BC(bcType,varargin)
        end
    end
end

%!test граничные условия типа закрепление
%!
%!test граничные условия типа плоскость симметрии
%!
%!test граничные условия типа заданные перемещения
%!
