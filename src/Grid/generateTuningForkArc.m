function grid = generateTuningForkArc(p)
% Параметры геометрии (все размеры в см)
X_prong = 4.5;      % длина зубьев 
Y_prong = 0.125;     % сечение зубьев (квадрат)
Z_prong = 0.125;     
gap = 0.9;          % расстояние между осями зубьев
X_handle = 2.6;    % длина ручки
Z_handle = Z_prong/2;      

% Параметры дискретизации 
Nz = 2 * p;             % число элементов по ширине сечения
Ny = 2 * p;             % по глубине
Nx_prong = 32 * p;      % по длине зуба
Nx_handle = 10 * p;     % по длине ручки
Ntheta = 4 * p;

% --- 1. Генерация блоков ---

% Левый зуб (ось X от 0 до L_prong, центр Y = +gap/2)
toothL = generateCube(X_prong, Y_prong, Z_prong, Nx_prong, Ny, Nz);
toothL.nodes(2,:) = toothL.nodes(2,:) + gap/2;  % смещение по Y

% Правый зуб (ось X от 0 до L_prong, центр Y = -gap/2)
toothR = generateCube(X_prong, Y_prong, Z_prong, Nx_prong, Ny, Nz);
toothR.nodes(2,:) = toothR.nodes(2,:) - gap/2 - Y_prong;

R0 = 0.25;
arcR = generateArc(R0, R0 + Y_prong, Z_prong, pi, 3*pi/2, Ny, Ntheta, Nz);
arcR.nodes(2,:) = arcR.nodes(2,:) - gap/2 + R0; 
arcL = generateArc(R0, R0 + Y_prong, Z_prong, pi/2, pi, Ny, Ntheta, Nz);
arcL.nodes(2,:) = arcL.nodes(2,:) + gap/2 - R0;

Y_handle = min(arcL.nodes(2,:)) - max(arcR.nodes(2,:));
arcGap = generateCube(Y_prong,Y_handle,Z_prong, Ny, Ny, Nz);
arcGap.nodes(1,:) = arcGap.nodes(1,:) - Y_prong - R0;
arcGap.nodes(2,:) = arcGap.nodes(2,:) - gap/2 + R0;

% Ручка (вертикальная, ось Y, начинается в y = -R_bend, идёт вниз)
handle = generateCube(X_handle, Y_handle, Z_handle, Nx_handle, Ny, Nz/2);
% Смещаем ручку так, чтобы её верхний торец (y=0) оказался в y = -R_bend
handle.nodes(1,:) = handle.nodes(1,:) + min(arcGap.nodes(1,:)) - X_handle;
handle.nodes(2,:) = handle.nodes(2,:) - Y_handle/2;
% handle.nodes(3,:) = handle.nodes(3,:) + 0.25 * Z_prong;   

% --- 2. Объединение всех блоков ---
grid = mergeGrids(toothL, toothR, arcL, arcR, arcGap, handle);

% --- 3. Слияние узлов на стыках (допуск 1e-4 см) ---
grid = mergeNodes(grid, 1e-4);
