classdef StressCalculator
    methods (Static)
        function [vonMises, principal] = computeStresses(solver)
            nRegions = numel(solver.lastSolution.regions);
            vonMises = cell(nRegions, 1);
            principal = cell(nRegions, 1);

            for r = 1:nRegions
                region = solver.lastSolution.regions(r);
                nElements = numel(region.elementIndices);

                % Предварительное выделение памяти
                vonMises{r} = zeros(nElements, 1);
                principal{r} = zeros(nElements, 3);

                for i = 1:nElements
                    u_e = solver.lastSolution.displacements(region.hexas(i, :));
                    strains = region.B_matrices(:,:,i) * u_e(:);
                    stresses = region.D_matrix * strains;

                    [vonMises{r}(i), principal{r}(i,:)] = ...
                        StressCalculator.computeVonMises(stresses);
                end
            end

            % Объединение результатов всех регионов
            vonMises = vertcat(vonMises{:});
            principal = vertcat(principal{:});
        end
    end
end

classdef StressCalculator < handle
    properties
        visualizer = []   % Прикрепленный визуализатор
        visibleElements = [] % Фильтр элементов для отображения
        stressData = struct() % Кеш результатов
    end

    methods
        function attachVisualizer(obj, viz)
            obj.visualizer = viz;
        end

        function setVisibleElements(obj, elementIndices)
            obj.visibleElements = elementIndices;
        end

        function [vonMises, principal] = compute(obj, solver, mesh)
            % 1. Получаем перемещения и матрицы
            U = solver.lastSolution.U;
            elements = mesh.getElementObjects(); % Массив Hex8/Tet4

            % 2. Вычисляем напряжения для каждого элемента
            nElems = numel(elements);
            vonMises = zeros(nElems, 1);
            principal = zeros(nElems, 3);

            for i = 1:nElems
                elem = elements{i};
                nodes = mesh.nodes(elem.nodeIndices, :);

                % 2.1. Получаем матрицу B и перемещения элемента
                B = elem.computeBMatrix(nodes);
                u_e = U(elem.dofIndices); % Локальные степени свободы

                % 2.2. Вычисляем напряжения
                strains = B * u_e;
                stresses = elem.material.D * strains;

                % 2.3. Напряжения Мизеса и главные напряжения
                [vonMises(i), principal(i,:)] = obj.computeVonMises(stresses);
            end

            % 3. Сохраняем результаты
            obj.stressData.vonMises = vonMises;
            obj.stressData.principal = principal;

            % 4. Визуализация (если подключен visualizer)
            if ~isempty(obj.visualizer)
                vizData = obj.prepareVizData(mesh);
                obj.visualizer.renderStress(vizData);
            end
        end

        function vizData = prepareVizData(obj, mesh)
            % Фильтрация данных по visibleElements
            if isempty(obj.visibleElements)
                elemIndices = 1:numel(mesh.hexas);
            else
                elemIndices = obj.visibleElements;
            end

            vizData = struct();
            vizData.vonMises = obj.stressData.vonMises(elemIndices);
            vizData.principal = obj.stressData.principal(elemIndices, :);
            vizData.mesh = mesh.getFilteredCopy(elemIndices);
        end

        function [vm, pr] = computeVonMises(~, stresses)
            % Формула для Мизеса и главных напряжений
            s = stresses([1 2 3 4 5 6]); % σxx, σyy, σzz, τxy, τyz, τxz
            vm = sqrt(0.5*((s(1)-s(2))^2 + (s(2)-s(3))^2 + (s(3)-s(1))^2 + 6*(s(4)^2 + s(5)^2 + s(6)^2));

            stressTensor = [s(1) s(4) s(6);
                           s(4) s(2) s(5);
                           s(6) s(5) s(3)];
            pr = eig(stressTensor)';
        end
    end
end
