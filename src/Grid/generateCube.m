function grid = generateCube(X, Y, Z, Nx, Ny, Nz)
    % Прямоугольный брус: ось Y, сечение X×Z.
    % X - ширина по X, Y - глубина по Y, Z - высота по Z.
    % Nx, Ny, Nz - число элементов по соответствующим направлениям.
    grid = Grid3D();
    
    nx = Nx + 1; 
    ny = Ny + 1; 
    nz = Nz + 1;
    
    x = linspace(0, X, nx);
    y = linspace(0, Y, ny);
    z = linspace(0, Z, nz);

    nodes = zeros(3, nx*ny*nz);
    idx = 1;
    for k = 1:nz          % z
        for j = 1:ny      % y
            for i = 1:nx  % x
                nodes(:, idx) = [x(i); y(j); z(k)];
                idx = idx + 1;
            end
        end
    end
    grid.nodes = nodes;

    hexas = zeros(8, Nx * Ny * Nz);
    eidx = 1;
    getNode = @(i,j,k) (k-1)*ny*nx + (j-1)*nx + i;  % i-x, j-z, k-y
    for k = 1:Nz
        for j = 1:Ny
            for i = 1:Nx
                n1 = getNode(i,   j,   k);
                n2 = getNode(i+1, j,   k);
                n3 = getNode(i+1, j+1, k);
                n4 = getNode(i,   j+1, k);
                n5 = getNode(i,   j,   k+1);
                n6 = getNode(i+1, j,   k+1);
                n7 = getNode(i+1, j+1, k+1);
                n8 = getNode(i,   j+1, k+1);
                hexas(:, eidx) = [n1; n2; n3; n4; n5; n6; n7; n8];
                eidx = eidx + 1;
            end
        end
    end
    grid.hexas = hexas;
    grid.generateQuads();
end