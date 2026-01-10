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
            obj.displacementScale = 1.0;
            obj.patchHandle.mesh = patch(obj.axHandle, 'Faces', grid.quads', 'Vertices', grid.nodes','FaceColor','c','Clipping','Off');

            title(obj.axHandle, grid.name);
            obj.grid = grid;
        end

        function showDisplacements(obj, displacements, scale)
            if ~isgraphics(obj.patchHandle.mesh)
                return;
            end
            if nargin < 3
                scale = obj.displacementScale;
            end
            deformedNodes = obj.grid.nodes + scale * displacements;
            set(obj.patchHandle.mesh, 'Vertices', deformedNodes');
            title([obj.grid.name, sprintf(':Перемещения (масштаб: %.2f)', scale)]);
        end

        function showField(obj, field)
            if ~isgraphics(obj.patchHandle.mesh)
                return;
            end
            set(obj.patchHandle.mesh, 'facecolor', 'interp');
            set(obj.patchHandle.mesh, 'facevertexcdata', field(:));
            colorbar;
        end
        
        function showForce(obj, force, scale)
            if nargin < 3
                scale = 1;
            end
            force = scale * force;
            x = obj.grid.nodes(1,:);
            y = obj.grid.nodes(2,:);
            z = obj.grid.nodes(3,:);
            u = force(1,:);
            v = force(2,:);
            w = force(3,:);
            hold on;
            if scale < 0
               x = x + u;
               y = y + v;
               z = z + w;
               u = -u;
               v = -v;
               w = -w;
            end
            obj.patchHandle.force = quiver3(obj.axHandle,x,y,z,u,v,w,'off','Clipping','Off');
            hold off;
        end

        function showAttach(obj, attach)
            hold on;
            obj.patchHandle.attach = scatter3(obj.axHandle,obj.grid.nodes(attach,1),obj.grid.nodes(attach,2),obj.grid.nodes(attach,3),"r",'+','Clipping','Off');
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
    end
end
