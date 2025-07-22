classdef ForceData < handle
    properties
        nodal_forces    % Узловые силы [N×3]
        surface_forces  % Поверхностные силы (для элементов)
        body_forces     % Объёмные силы [M×3]
    end
end
