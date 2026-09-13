function grid = generateCylinder(r_inner, r_outer, H, Nr, Ntheta, Nz)      %r_inner=внутренний радиус  r_outer=внешний радиус  H=высота цилиндра
    % Установка значений по умолчанию                                %Ntheta=количество элементов вдоль радиуса    
    if nargin < 6, Nz = 10; end                                      %Nz=количество элементов вдоль высоты
    if nargin < 5, Ntheta = 40; end
    if nargin < 4, Nr = 40; end
    if nargin < 3, H = 10; end
    if nargin < 2, r_outer = 15; end
    if nargin < 1, r_inner = 5; end

    grid = Grid3D();

    nR = Nr + 1;
    nT = Ntheta;          
    nZ = Nz + 1;

    % Координаты узлов: углы от 0 до 2*pi
    r = linspace(r_inner, r_outer, nR);
    theta = linspace(0, 2*pi, nT+1);
    theta = theta(1:end-1);   % убираем 2*pi, чтобы не дублировать узел при 0
    z = linspace(0, H, nZ);

    nodes = zeros(3, nR * nT * nZ);
    idx = 1;
    for k = 1:nZ
        for j = 1:nT
            for i = 1:nR
                x = r(i) * cos(theta(j));
                y = r(i) * sin(theta(j));
                nodes(:, idx) = [x; y; z(k)];
                idx = idx + 1;
            end
        end
    end

    grid.nodes = nodes;
    hexas = zeros(8, Nr * Ntheta * Nz);
    elemIdx = 1;

    % Функция линейного индекса узла: i – радиус (1..nR), j – угол (1..nT), k – слой (1..nZ)
    getNode = @(i, j, k) (k-1)*nT*nR + (j-1)*nR + i;

    for k = 1:Nz
        for j = 1:Ntheta
            % Следующий угол: если j == Ntheta, то замыкаем на 1
            j_next = j + 1;
            if j_next > nT
                j_next = 1;
            end
            for i = 1:Nr
                n1 = getNode(i,   j,      k);
                n2 = getNode(i+1, j,      k);
                n3 = getNode(i+1, j_next, k);
                n4 = getNode(i,   j_next, k);
                n5 = getNode(i,   j,      k+1);
                n6 = getNode(i+1, j,      k+1);
                n7 = getNode(i+1, j_next, k+1);
                n8 = getNode(i,   j_next, k+1);

                hexas(:, elemIdx) = [n1; n2; n3; n4; n5; n6; n7; n8];
                elemIdx = elemIdx + 1;
            end
        end
    end
    grid.hexas = hexas;
    grid.generateQuads();  
end