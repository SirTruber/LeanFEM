classdef Visualizer < handle
    properties
        figHandle, %for export png/gif, action handle
        axHandle, %for hold on/off, subplot, custom axes
        patchHandle, %for caching object
        colorMap, % different color for regions, VM stress
        displacementScale %
    end
    methods
        function obj = Visualizer()
            obj.figHandle = figure;
            obj.axHandle = axes('Parent', obj.figHandle);
            axis(obj.axHandle, 'equal');
            obj.colorMap = turbo(256);
            obj.displacementScale = 1.0;
        end

        function show(obj, target)

        end

        function showMesh(obj,mesh) %TODO check
            obj.patchHandle.mesh = patch(obj.axHandle, 'Faces', mesh.quads, 'Vertices', mesh.nodes, 'FaceColor', 'flat', 'EdgeColor', 'k');
            title(obj.axHandle, mesh.name);
        end

        function showRegions(obj,mesh) %TODO check
            hold (obj.axHandle, 'on');
            regions = mesh.regions; %only 25 regions is allowed
            for i = 1:numel(regions)
                faces = mesh.quads(ismember(mesh.hexas, regions(i).elementIndices), :);
                patch( obj.axHandle, 'Faces', faces, 'Vertices', obj.grid.nodes, 'FaceColor', obj.colorMap(i*10, :), 'EdgeColor', 'none');
            end
            legend(obj.axHandle, {regions.name});
            hold (obj.axHandle, 'off');
        end

        function showDisplacements(obj, displacements, scale)
            if ~isfield(obj.patchHandles, 'mesh')
                return;
            end
            if nargin < 3
                scale = obj.displacementScale;
            end
            deformedNodes = obj.grid.nodes + scale * displacements;
            set(obj.patchHandles.mesh, 'Vertices', deformedNodes);
            title([obj.grid.name, sprintf(':Деформации (масштаб: %.2f)', scale)]);
        end

        function update(obj)
            if isfield(obj.patchHandles, 'mesh')
                set(obj.patchHandles.mesh, 'Vertices', obj.grid.nodes);
            end
        end
    end

%         centers = getElementCenters(grid); % [nElems x 3]
% principalStresses = ...; % [nElems x 3] (σ1, σ2, σ3)
%
% colors = principalStresses(:,1); % Используем σ1 для цвета
% colors = (colors - min(colors)) / (max(colors) - min(colors));
%
% % Рисуем векторы
% hold on;
% for i = 1:size(principalStresses,1)
%     quiver3(centers(i,1), centers(i,2), centers(i,3), ...
%             principalStresses(i,1), principalStresses(i,2), principalStresses(i,3), ...
%             'Color', [colors(i) 0 1-colors(i)], 'LineWidth', 1.5, ...
%             'MaxHeadSize', 0.5);
% end
% hold off;
%     end
end
