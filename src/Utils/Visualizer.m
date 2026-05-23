classdef Visualizer < handle
    properties
        figHandle   % for export png/gif, action handle
        axHandle    % for hold on/off, subplot, custom axes
        patchHandle % for caching object
        colorMap = turbo(256)% different color for regions, VM stress
        displacementScale = 1.0%
        grid
    end
    methods
        function obj = Visualizer(grid)
            obj.grid = grid;
            obj.figHandle = figure;
            obj.axHandle = axes('Parent', obj.figHandle);
            axis(obj.axHandle, 'equal');
            obj.patchHandle.mesh = patch(obj.axHandle, ...
                'Faces', grid.quads',...
                'Vertices', grid.nodes', ...
                'FaceColor','c',...
                'Clipping','Off');
            title(obj.axHandle, grid.name);
        end

        function showDisplacements(obj, displacements, scale)
            if ~ishandle(obj.patchHandle.mesh)
                return;
            end
            if nargin < 3
                scale = obj.displacementScale;
            end
            deformedNodes = obj.grid.nodes + scale * ensure3D(displacements);
            set(obj.patchHandle.mesh, 'Vertices', deformedNodes');
            title([obj.grid.name, sprintf(':Перемещения (масштаб: %.2f)', scale)]);
        end

        function showField(obj, field)
            if ~ishandle(obj.patchHandle.mesh)
                return;
            end
            set(obj.patchHandle.mesh, 'FaceColor', 'interp');
            set(obj.patchHandle.mesh, 'FaceVertexCData', field(:));
            colormap(obj.axHandle, obj.colorMap);
            colorbar;
        end
        
        function showForce(obj, force, scale)
            if nargin < 3
                scale = 1;
            end
            force = scale * ensure3D(force);
            x = obj.grid.nodes(1,:);
            y = obj.grid.nodes(2,:);
            z = obj.grid.nodes(3,:);
            u = force(1,:);
            v = force(2,:);
            w = force(3,:);
            hold(obj.axHandle, 'on');
            if scale < 0
               x = x + u;
               y = y + v;
               z = z + w;
               u = -u;
               v = -v;
               w = -w;
            end
            obj.patchHandle.force = quiver3(obj.axHandle,x,y,z,u,v,w,'off','color','red','Clipping','Off');
            hold(obj.axHandle, 'off');
        end

        function showAttach(obj, attach, dofMask)
        % attach – индексы узлов, в которых есть закрепления
        % dofMask – матрица 3×length(attach) типа logical (если true,
        %           то соответствующее перемещение UX, UY или UZ запрещено)
        % Если dofMask не задан, считается, что закреплены все три направления

        dofMask = ensure3D(dofMask)
        if nargin < 3
            dofMask = true(3, length(attach));  % полная заделка по умолчанию
        end

        % Координаты закреплённых узлов
        x = obj.grid.nodes(1, attach);
        y = obj.grid.nodes(2, attach);
        z = obj.grid.nodes(3, attach);

        % Характерный размер модели для автоматической длины отрезка
        [~,maxSpan] = obj.grid.bsphere();
        len = maxSpan * 0.05;          % 10% от радиуса

        % Цвета для осей X, Y, Z
        colors = [1 0 0;        % красный
                0 1 0;      % зелёный
                0 0 1];       % синий

        % Удаляем старые отметки закрепления
        if isprop(obj.patchHandle, 'attach') && ~isempty(obj.patchHandle.attach)
            delete(obj.patchHandle.attach(ishandle(obj.patchHandle.attach)));
        end
        obj.patchHandle.attach = [];

        hold(obj.axHandle, 'on');

        % Рисуем чёрные залитые кружки в местах узлов
        hNodes = scatter3(obj.axHandle, x, y, z, maxSpan * 0.01, 'k', 'filled');
        obj.patchHandle.attach = [obj.patchHandle.attach, hNodes];

        % Для каждого узла строим отрезки по закреплённым направлениям
        for i = 1:length(attach)
            xi = x(i); yi = y(i); zi = z(i);

            if dofMask(1, i)   % UX
                hl = plot3(obj.axHandle, [xi-len, xi+len], [yi, yi], [zi, zi], ...
                            'Color', colors(1,:), 'LineWidth', 2);
                    obj.patchHandle.attach = [obj.patchHandle.attach, hl];
            end
            if dofMask(2, i)   % UY
                hl = plot3(obj.axHandle, [xi, xi], [yi-len, yi+len], [zi, zi], ...
                        'Color', colors(2,:), 'LineWidth', 2);
                        obj.patchHandle.attach = [obj.patchHandle.attach, hl];
            end
            if dofMask(3, i)   % UZ
                hl = plot3(obj.axHandle, [xi, xi], [yi, yi], [zi-len, zi+len], ...
                        'Color', colors(3,:), 'LineWidth', 2);
                obj.patchHandle.attach = [obj.patchHandle.attach, hl];
            end
        end

        hold(obj.axHandle, 'off');
    end
    #     function showAttach(obj, attach)
    #         hold(obj.axHandle, 'on');
    #         obj.patchHandle.attach = plot3(obj.axHandle, ...
    # obj.grid.nodes(1, attach), obj.grid.nodes(2, attach), obj.grid.nodes(3, attach), ...
    # '^', 'Color', 'black', 'MarkerSize', 5, 'LineWidth', 2);
    #         # obj.patchHandle.attach = scatter3(obj.axHandle,...
    #             # obj.grid.nodes(1,attach),...
    #             # obj.grid.nodes(2,attach),...
    #             # obj.grid.nodes(3,attach),...
    #             # '+','color',[0 0.2 0.7],...
    #             # 'MarkerSize', 50, ...
    #             # 'Clipping','Off');
    #         hold(obj.axHandle, 'off');
    #     end

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

function out = ensure3D(data)
    if size(data, 1) == 2
        out = [data; zeros(1, size(data, 2))];
    elseif size(data, 1) == 3
        out = data;
    else
        error('Данные должны иметь 2 или 3 строки (компоненты).');
    end
end
