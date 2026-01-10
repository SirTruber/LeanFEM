function [K,M] = assemble(fe,grid)
    DIM = fe.numDIM;
    n = grid.numElements();
    m = fe.numDIM * grid.numNodes();

    ij = DIM * repelem(grid.elements(1:n),DIM,1) - repmat(int32(DIM-1:-1:0)',fe.numNODE, grid.numElements); % Принимаем допущение, что узлы ячеек совпадают с узлами конечных элементов. 
    [i,j] = ndgrid(1:fe.numDOF, 1:fe.numDOF);                                                               % Для ажурных и элементов с дополнительными узлами нужно проводить дополнительное отображение
    i_glob = ij(i(:),:);
    j_glob = ij(j(:),:);
    stiffness = arrayfun(@(i) fe.stiffness(grid.points(i)),1:n,'UniformOutput',false); % Вычисляем матрицы жёсткости сразу для всех элементов
    stiffness = cat(3, stiffness{:}); % Объединяем в 3D-массив 
    K = sparse(i_glob(:), j_glob(:),stiffness(:),m,m); % Создаём глобальную матрицу
            
    if nargout == 2
        mass = arrayfun(@(i) fe.mass(grid.points(i)),1:n,'UniformOutput',false); % Вычисляем матрицы масс сразу для всех элементов
        mass = cat(3, mass{:}); % Объединяем в 3D-массив 
        M = sparse(i_glob(:), j_glob(:),mass(:),m,m); % Создаём глобальную матрицу
    end
end