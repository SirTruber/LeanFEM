classdef Visualizer < handle
    properties
        figHandle   % for export png/gif, action handle
        axHandle    % for hold on/off, subplot, custom axes
        patchHandle % for caching object
        colorMap    % different color for regions, VM stress
        displacementScale %
        grid
    end
    methods
        function obj = Visualizer(grid)
            obj.figHandle = figure;
            obj.axHandle = axes('Parent', obj.figHandle);
            axis(obj.axHandle, 'equal');
            obj.colorMap = turbo(256);
%             colorbar;
            obj.displacementScale = 1.0;
            obj.patchHandle.mesh = patch(obj.axHandle, 'Faces', grid.quads, 'Vertices', grid.nodes, 'FaceColor', 'flat', 'EdgeColor', 'k');

            title(obj.axHandle, grid.name);
            obj.grid = grid;
        end

        function showRegions(obj, regions) %TODO check
            if numel(regions) > 25
                warning('Рекомендуется не более 25 регионов');
            end
            colorData = zeros(size(get(obj.patchHandle.mesh,'faces'),1),1);
            for i = 1:numel(regions)
                if regions{i}.dimension == 2
                    colorData(regions{i}.elements) = i;
                end
            end
            colorData = colorData * 10;
            set(obj.patchHandle.mesh,'FaceVertexCData', colorData);
        end

        function showDisplacements(obj, displacements, scale)
            if ~isfield(obj.patchHandle, 'mesh')
                return;
            end
            if nargin < 3
                scale = obj.displacementScale;
            end
            deformedNodes = obj.grid.nodes + scale * reshape(displacements,3,[])';
            set(obj.patchHandle.mesh, 'Vertices', deformedNodes);
            title([obj.grid.name, sprintf(':Деформации (масштаб: %.2f)', scale)]);
        end

        function showForce(obj, force, scale)
            if nargin < 3
                scale = 1;
            end
            hold on;
            if scale > 0
                obj.patchHandle.force = quiver3(obj.axHandle,obj.grid.nodes(:,1),obj.grid.nodes(:,2),obj.grid.nodes(:,3),scale*force(:,1),scale*force(:,2),scale*force(:,3),'off');
            else
                obj.patchHandle.force = quiver3(obj.axHandle,obj.grid.nodes(:,1) + scale * force(:,1),obj.grid.nodes(:,2) + scale * force(:,2),obj.grid.nodes(:,3) + scale*force(:,3),-scale*force(:,1),-scale*force(:,2),-scale*force(:,3),'off');
            end
            hold off;
        end

        function showAttach(obj, attach)
            hold on;
            obj.patchHandle.attach = scatter3(obj.axHandle,obj.grid.nodes(attach,1),obj.grid.nodes(attach,2),obj.grid.nodes(attach,3),"r",'+');
            hold off;
        end

        function writePNG(obj,path)
            img = print('-RGBImage');
            imwrite(img, path);
        end

        function writeGIF(obj,path,DelayTime)
            img = print('-RGBImage');
            imwrite(img, path,'DelayTime',DelayTime,'Compression','bzip','WriteMode','Append');
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
