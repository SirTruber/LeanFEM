function [U, strainPl, stress] = Plasticity(problem, mesh, bc, force, maxIter)
% Plasticity - упругопластический расчёт методом начальных напряжений
%   problem : объект AbstractProblem (SolidElasticity, PlaneStress, ...)
%   mesh    : объект GridData
%   bc      : структура с полями dofIndices, dofValues
%   force   : вектор внешних сил (totalDOF x 1)
%   maxIter : максимальное число итераций
%   tol     : допуск по относительной норме изменения пластической деформации

if nargin < 5, maxIter = 10; end

tol1 = 1e-6;
tol2 = 1e-6;

% === 1. Инициализация ===
assembler = Assembler(problem, mesh);
K = assembler.stiffness();                     % глобальная упругая матрица
solver = Static(assembler);
solver.applyBC(bc, bc);

numEl     = mesh.numElements();
numNodes  = mesh.numNodes();
dofPerNode = problem.dofPerNode;
totalDOF  = dofPerNode * numNodes;

element   = problem.element;
nQuad     = element.quadrature.nPoints;
C         = problem.elasticityMatrix();
mu        = problem.material.secondLame;
sigmaY    = problem.material.yieldStress;      % необходимо добавить в Material

% История пластической деформации
strainSize = problem.strainSize;
strainP    = zeros(strainSize, nQuad, numEl);

for forceIter = 1:1000
F = force .* (forceIter/1000);
forceIter
% === 2. Итерации метода начальных напряжений ===
converged = false;
for iter = 1:maxIter

    dStrainP      = zeros(strainSize, nQuad, numEl);
    dStrainP_prev = zeros(strainSize, nQuad, numEl);

    % 2.1 Сборка пластических сил F_pl = ∫ B^T * C * (ε_p + dε_p) dV
    F_pl = zeros(totalDOF, 1);
    for e = 1:numEl
        nodes = mesh.elements(e);
        nodeCoords = mesh.points(e);
        % Интегрирование по элементу
        val = 0;
        for ip = 1:nQuad
            xi = element.quadrature.points(:, ip);
            w = element.quadrature.weights(ip);

            [grad, detJ] = element.computeGradient(xi, nodeCoords);
            N = element.shapeFunction(xi);

            B = problem.strainDisplacementMatrix(grad, N, nodeCoords);
            C = problem.elasticityMatrix();
            epsP = strainP(:,ip,e) + dStrainP(:,ip,e);
            f = B' * C * epsP;   % вектор узловых сил (dofPerElem x 1)
            val = val + f * detJ * w;
        end
        F_pl_e = val * 1/dofPerNode;
        % Ансамблирование
        dofMap = reshape((dofPerNode * (nodes(:)'-1) + (1:dofPerNode)'), [], 1);
        F_pl(dofMap) = F_pl(dofMap) + F_pl_e;
    end

    % 2.2 Решение упругой задачи: K * U = F_ext + F_pl
    solver.step(F(:) + F_pl);
    U = solver.U;

    % 2.3 Обновление пластических деформаций
    for e = 1:numEl
        nodes = mesh.elements(e);
        nodeCoords = mesh.points(e);
        Ue = reshape(U(dofPerNode*(nodes(:)'-1) + (1:dofPerNode)'), [], 1);

        for ip = 1:nQuad
            xi = element.quadrature.points(:, ip);
            [grad, ~] = element.computeGradient(xi, nodeCoords);
            N = element.shapeFunction(xi);
            B = problem.strainDisplacementMatrix(grad, N, nodeCoords);

            epsilon = B * Ue;
            epsE_tr = epsilon - strainP(:, ip, e);
            sigma_tr = C * epsE_tr;

            % Радиальный возврат
            vm = problem.vonMises(sigma_tr);
            f = vm - sigmaY;
            if f > 0
                % девиатор пробных напряжений
                s = sigma_tr;
                p = mean(sigma_tr(1:3));
                s(1:3) = s(1:3) - p;

                dLambda = 0.5 * f / (sigmaY * mu);
                dEpsP = ( dLambda / (1 + 2*mu*dLambda)) * s;

                dStrainP(:, ip, e) = dEpsP;
            end
        end
    end

    % 2.4 Проверка сходимости
    delta = dStrainP - dStrainP_prev;
    normDelta = norm(delta(:))
    normP = norm(strainP(:));
    if normDelta < tol1 * normP + tol2
        converged = true;
        break;
    end
    dStrainP_prev = dStrainP;
end

strainP = strainP + dStrainP;

if ~converged
    warning('Plasticity: не сошлось за %d итераций, норма изменения = %e', maxIter, normDelta);
end
end
% === 3. Постобработка: узловые значения пластической деформации и напряжения ===
strainPl = zeros(strainSize, numNodes);
stress   = zeros(strainSize, numNodes);
weight   = zeros(1, numNodes);

for e = 1:numEl
    nodes = mesh.elements(e);
    nodeCoords = mesh.points(e);
    Ue = reshape(U(dofPerNode*(nodes(:)'-1) + (1:dofPerNode)'), [], 1);

    % Веса узлов (∫ N dV) — уже готовый метод
    w = problem.nodeWeight(nodeCoords);   % 1 x numNodesPerElem
    Ve = sum(w);                           % объём элемента

    % Интеграл пластической деформации по элементу (∫ B*Ue - ε_p dV)
    strainIntegral = problem.strainIntergal(nodeCoords, Ue);  % ∫ B*Ue dV
    % Вычитаем интеграл пластической деформации
    for ip = 1:nQuad
        xi = element.quadrature.points(:, ip);
        w_ip = element.quadrature.weights(ip);
        [~, detJ] = element.computeGradient(xi, nodeCoords);
        N = element.shapeFunction(xi);
        dV = detJ * w_ip;
        strainIntegral = strainIntegral - dV * strainP(:, ip, e);   % ∫ ε_p dV
    end

    % Узловые значения по формуле: (strainIntegral .* (w/Ve)) ./ weight
    strainElastic = strainIntegral .* (w / Ve);   % [strainSize x numNodesPerElem]
    stress(:, nodes) = stress(:, nodes) + C * strainElastic;
    weight(nodes) = weight(nodes) + w;

    % Пластическая деформация в узлы
    for ip = 1:nQuad
        xi = element.quadrature.points(:, ip);
        w_ip = element.quadrature.weights(ip);
        [~, detJ] = element.computeGradient(xi, nodeCoords);
        N = element.shapeFunction(xi);
        dV = detJ * w_ip;
        strainPl(:, nodes) = strainPl(:, nodes) + (strainP(:, ip, e) .* N') * dV;
    end
end
strainPl = strainPl ./ weight;   % нормализация
stress = stress ./ weight;
end

% === Локальная функция для вклада пластических сил ===
function f = localPlasticForce(xi, grad, detJ, N, ip, problem, nodeCoords, epsP)
    B = problem.strainDisplacementMatrix(grad, N, nodeCoords);
    C = problem.elasticityMatrix();
    f = B' * C * epsP;   % вектор узловых сил (dofPerElem x 1)
end
