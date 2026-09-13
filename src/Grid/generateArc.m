function grid = generateArc(r_inner, r_outer, H, theta_start, theta_end, Nr, Ntheta, Nz)
    % Дуга окружности с прямоугольным сечением (радиальное × осевое Z).
    % r_inner - внутренний радиус, r_outer - внешний радиус, H - высота по Z.
    % Углы в радианах.
    grid = Grid3D();
    
    nR = Nr + 1; 
    nT = Ntheta + 1;
    nZ = Nz + 1; 
    
    r = linspace(r_inner, r_outer, nR);
    theta = linspace(theta_start, theta_end, nT);
    z = linspace( 0, H, nZ);
    
    nodes = zeros(3, nR * nT * nZ);
    idx = 1;
    for k = 1:nZ          % z
        for j = 1:nT      % theta
            for i = 1:nR  % r
                x = r(i) * cos(theta(j));
                y = r(i) * sin(theta(j));
                nodes(:, idx) = [x; y; z(k)];
                idx = idx + 1;
            end
        end
    end
    grid.nodes = nodes;
    hexas = zeros(8, Nr * Ntheta * Nz);
    eidx = 1;
    getNode = @(i,k,j) (j-1)*nT*nR + (k-1)*nR + i;
    for k = 1:Nz
        for j = 1:Ntheta
            for i = 1:Nr
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