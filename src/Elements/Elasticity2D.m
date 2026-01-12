classdef Elasticity2D < Element
    properties
        numDIM = 2;
        material % Материал элемента
        elasticity  % Матрица упругих постоянных(симметричная, положительно определённая)
        thick
        planeStrain
    end
    methods
        function obj = Elasticity2D(material,nquad)
            obj = obj@Element(nquad);
            obj.material = material;
            obj.setPlaneStrain() % По умолчанию - плоская деформация
        end

        function setPlaneStrain(obj)
            obj.planeStrain = true;
            obj.thick = 1; % Принимаем толщину за единицу при плоской деформации
            obj.material.firstLameStar = obj.material.firstLame; % Добавляем дополнительные поля для эффективных параметров. Параметры материала не отличаются от 3D напряжения
            obj.material.secondLameStar = obj.material.secondLame;
            obj.elasticity = blkdiag(obj.material.firstLameStar(ones(2)) + 2 * obj.material.secondLameStar * eye(2), obj.material.secondLameStar); % Собираем матрицу упругих постоянных
        end

        function setPlaneStress(obj,thickness)
            obj.planeStrain = false;
            obj.thick = thickness;
            Eef = obj.material.youngModule / (1 - obj.material.poissonRatio^2); % Для плоского напряжённого состояния нужно вычислить эффективные модули упругости
            nuef = obj.material.poissonRatio / (1 - obj.material.poissonRatio);
            matEF = Material(obj.material.name,obj.material.density,Eef,nuef); % Создаём отдельный материал для автоматического вычисления параметров Ламе

            obj.material.firstLameStar = matEF.firstLame; % Присваиваем нашему материалу эффективные параметры другого материала
            obj.material.secondLameStar = matEF.secondLame;
            obj.elasticity = blkdiag(obj.material.firstLameStar(ones(2)) + 2 * obj.material.secondLameStar * eye(2), obj.material.secondLameStar); % Собираем матрицу упругих постоянных
        end

        function K = stiffness(obj,nodeCoords)
            K = zeros(obj.numDOF);
            n = numel(obj.gaussP);
            for i = 1 : n
                for j = 1 : n
                    intPoint = obj.gaussP([i,j]); % координаты точки интегрирования
                    [grad,detJ] = obj.computeGradient(intPoint,nodeCoords);
                    B = obj.gradMatrix(grad); % Вычисляем градиентную матрицу ( связь деформаций и перемещений)
                    G = B' * obj.elasticity * B * detJ; % Вычисляем значение подынтегральной функции
                        
                    w = prod(obj.gaussW([i,j])); % Вычисляем вес точки интегрирования
                    K = K + w * G; % Добавляем к общему интегралу, умножив на вес
                end
            end
        end

        function M = mass(obj,nodeCoords)
            M = obj.volume(nodeCoords) * obj.material.density * eye(obj.numDOF) / obj.numDOF; % Матрица масс принимается сосредоточенной в узлах (без связи между узлами)
        end

        function B = gradMatrix(obj,grad)
            n = obj.numDOF;
            p = obj.numDIM;
            B = zeros(3, n);

            B(1,1:p:n) = grad(1,:); %εxx
            B(2,2:p:n) = grad(2,:); %εyy

            B(3,1:p:n) = grad(2,:); %γxy
            B(3,2:p:n) = grad(1,:); %γyx
        end


        function [strain,stress] = evaluateStrainAndStress(obj, grid, U) % Вычисляет значение деформаций и напряжений в узлах
            numNodes = grid.numNodes();  % Число узлов
            numEl = grid.numElements();  % Число ячеек
            n = numel(obj.gaussP);

            strain = zeros(6,numNodes);  % Значения деформаций в узлах
            stress = zeros(6,numNodes);  % Значения напряжений в узлах
            weight = zeros(1,numNodes);
            for p = 1:numEl % Для каждой ячейки:
                nodes = grid.elements(p); % Достаём номера узлов элемента
                points = grid.points(p); % Достаём координаты узлов элемента
                volume = obj.volume(points); 
                weight(nodes) = weight(nodes) + volume;
                Ue = U(:,nodes); % Достаём перемещения узлов ячейки
                for i = 1 : n 
                    for j = 1 : n
                        intPoint = obj.gaussP([i;j]); % координаты точки интегрирования
                        [grad,~] = obj.computeGradient(intPoint,points); % Вычисляем градиенты и якобиан в точке интегрирования
                        B = obj.gradMatrix(grad); % Вычисляем градиентную матрицу ( связь деформаций и перемещений)
                        shape = obj.shapeFunction(intPoint);
                        strainEl = B * Ue(:) .* shape';
                        w = volume * prod(obj.gaussW([i,j])); % Вычисляем вес точки интегрирования
                        strain([1,2,4],nodes) = strain([1,2,4],nodes) + w * strainEl; % Добавляем к общему значению, умножив на вес
                    end
                end
            end
            strain = strain./weight; % Берем средне взвешенное, где вес пропорционален объёму ячейки s = sum(si*wi/sum(wi))
            stress([1,2,4],:) = 1e5 * obj.elasticity * strain([1,2,4],:); % Возвращаем напряжения в МПа
            if obj.planeStrain
                stress(3,:) = obj.material.poissonRatio * (stress(1,:) + stress(2,:)); % Напряжение вдоль бесконечной оси возникает из-за эффекта Пуассона
            else
                strain(3,:) = obj.material.poissonRatio/(obj.material.poissonRatio -1 ) * (strain(1,:) + strain(2,:)); %Деформация для тонкой пластины по толщине в силу эффекта Пуассона
            end
        end

        function vM = vonMises(obj,stress) % Вычисляет эквивалентное напряжение Фон Мизеса
            vM = sqrt(0.5 * ((stress(1,:) - stress(2,:)).^2 + (stress(2,:) - stress(3,:)).^2 + (stress(3,:) - stress(1,:)).^2 + 6 * stress(4,:).^2));
        end  

        function v = volume(obj,nodeCoords)
            v = obj.thick * 4 * det(obj.jacobian([0,0],nodeCoords)); % Интегрируем по площади, умножаем на толщину
        end
        %function v = volume(obj,nodeCoords)
        %    X = (nodeCoords(1,1) - nodeCoords(1,3)) * (nodeCoords(2,2) - nodeCoords(2,4));  %Используем формулу естественнойаппроксимации производных, 
        %    Y = (nodeCoords(1,2) - nodeCoords(1,4)) * (nodeCoords(2,3) - nodeCoords(2,1));  % или так называемую формулу "шнуровки"
        %    v = obj.thick * 0.5 * abs(X + Y); % домножаем площадь на толщину
        %end
        function h = minHeight(obj,nodeCoords)
            edges = [1 2; 2 3; 3 4; 4 1]; % Номера узлов, образующих рёбра квадрата

            edges = nodeCoords(:,edges(:,2)) - nodeCoords(:,edges(:,1)); % Вектора, образующие рёбра квадрата
            len = sqrt(sum(edges.^2,2)); % Длина рёбер
            h = min(nonzeros(len)); % Длинна самого короткого ребра
        end
    end
end
