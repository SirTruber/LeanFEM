function [K,M] = assemble(problem,grid)
    dofPerNode = problem.dofPerNode; % число степеней свободы в узле
    dofPerElem = dofPerNode * problem.element.numNodes; % число степеней свободы в элементе
    numElements = grid.numElements(); % число элементов
    totalDOF = dofPerNode * grid.numNodes(); % число степеней свободы в системе

    ij = dofPerNode * repelem(grid.elements(1:numElements),dofPerNode,1) - ...                                 % Принимаем допущение, что узлы ячеек совпадают с узлами конечных элементов.
               repmat(int32(dofPerNode-1:-1:0)', problem.element.numNodes, numElements); % Для ажурных и элементов с дополнительными узлами нужно проводить дополнительное отображение
    [i,j] = ndgrid(1:dofPerElem, 1:dofPerElem);
    i_glob = ij(i(:),:);
    j_glob = ij(j(:),:);
    stiffness = arrayfun(@(i) problem.stiffness(grid.points(i)),1:numElements,'UniformOutput',false); % Вычисляем матрицы жёсткости сразу для всех элементов
    stiffness = cat(3, stiffness{:}); % Объединяем в 3D-массив
    K = sparse(i_glob(:), j_glob(:),stiffness(:),totalDOF,totalDOF); % Создаём глобальную матрицу

    if nargout == 2
        mass = arrayfun(@(i) problem.mass(grid.points(i)),1:numElements,'UniformOutput',false); % Вычисляем матрицы масс сразу для всех элементов
        mass = cat(3, mass{:}); % Объединяем в 3D-массив
        M = sparse(i_glob(:), j_glob(:),mass(:),totalDOF,totalDOF); % Создаём глобальную матрицу
    end
end
