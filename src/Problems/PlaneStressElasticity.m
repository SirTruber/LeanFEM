classdef PlaneStressElasticity < PlaneStrainElasticity
    properties
        thickness = 1.0   % толщина
    end

    methods
        function obj = PlaneStressElasticity(element, thickness)
            obj = obj@PlaneStrainElasticity(element);
            if nargin > 1, obj.thickness = thickness; end
        end

        function D = reduceTangent(obj, D3d)
            % Plane stress: stress_zz = stress_yz = stress_xz = 0
            % Делаем ортогональное отображение на плоскость
            in_plane     = [1, 2, 4];   % xx, yy, xy
            out_of_plane = [3, 5, 6];   % zz, yz, xz

            D_pp = D3d(in_plane, in_plane);
            D_po = D3d(in_plane, out_of_plane);
            D_op = D3d(out_of_plane, in_plane);
            D_oo = D3d(out_of_plane, out_of_plane);

            D = D_pp - D_po * (D_oo \ D_op);
        end

        function sv = reduceStress(obj, sv3d)
            sv = sv3d([1, 2, 4]);
        end

        function factor = volumeFactor(obj, ~)
            factor = obj.thickness;
        end
    end
end
