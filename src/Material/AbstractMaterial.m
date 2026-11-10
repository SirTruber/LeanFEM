classdef AbstractMaterial < handle
properties
    name        % строка
    density     % число
    isLinear    % булево
    supportedKinematics
    layout = struct(); % расположение полей в матрице состояний
    nVars  = 0;  % Число компонент в матрице состояний
end
methods
    % 3D тензор упругости 
    function D = elasticityMatrix(obj) 
        error("%s abstract elasticity",obj.name);
    end
    
    % Добавить нужное число полей в матрицу состояний
    function registerField(obj, field, width)
        idx = obj.nVars + (1:width);
        obj.layout.(char(field)) = idx;
        obj.nVars = obj.nVars + width;
    end

    % Создать матрцу состояний для каждой квадратурной точки каждого
    % элемента
    function state = initState(obj, nIP)
        state = zeros(obj.nVars, nIP);
    end

    % Найти строки, соответствующие field
    function n = getStateLayout(obj,field)
        fn = char(field);
        if ~isfield(obj.layout, fn)
            error('%s.getState: no field "%s"', obj.name, fn);
        end
        n = obj.layout.(fn);
    end

    % Извлечение значений по имени полей.
    % Быстрее извлечь stateLayout самому и иттерировать по state
    function v = getStateByName(obj, state, field)
        v = state(obj.getStateLayout(field), :);
    end

    % Установление значений по имени полей.
    % Быстрее извлечь stateLayout самому и иттерировать по state
    function state = setStateByName(obj, state, field, value)
        idx = obj.getStateLayout(field);
        if numel(value) ~= numel(idx)
            error('%s.setState: value has %d elements, field "%s" has %d', ...
                obj.name, numel(value), char(field), numel(idx));
        end
        state(idx, :) = value;
    end

    % Обновление состояния через малые деформации
    function state_new = updateSmall(obj, state_old, eps) %#ok<INUSD>
        error('%s: kinematics "small" not supported', obj.name);
    end
    
    % Обновление состояния через Updated Largangian
    function state_new = updateUL(obj, state_old, eps_dot, W, dt) %#ok<INUSD>
        error('%s: kinematics "UL" not supported', obj.name);
    end

    % Обновление состояния через Total Largangian
    function state_new = updateTL(obj, state_old, F) %#ok<INUSD>
        error('%s: kinematics "TL" not supported', obj.name);
    end

    % Переход от нотации Фойгта к тензору
    function S = voigtToTensorBatch(~, sv)
        % sv : [6 × nIP]
        n = size(sv, 2);
        S = zeros(3, 3, n);
        S(1,1,:) = sv(1,:); S(2,2,:) = sv(2,:); S(3,3,:) = sv(3,:);
        S(1,2,:) = sv(4,:); S(2,1,:) = sv(4,:);
        S(2,3,:) = sv(5,:); S(3,2,:) = sv(5,:);
        S(1,3,:) = sv(6,:); S(3,1,:) = sv(6,:);
    end

    % Переход от тензора к нотации Фойгта
    function sv = tensorToVoigtBatch(~, S)
        % S : [3 × 3 × nIP]
        sv = [reshape(S(1,1,:), 1, []); reshape(S(2,2,:), 1, []); ...
              reshape(S(3,3,:), 1, []); reshape(S(1,2,:), 1, []); ...
              reshape(S(2,3,:), 1, []); reshape(S(1,3,:), 1, [])];
    end

    function dS = jaumannBatch(~, S, W, dt)
        % dS = dt·(W·S − S·W), батч по 3-й размерности
        dS = (pagemtimes(W, S) - pagemtimes(S, W)) * dt;
    end

    function sv = applyJaumann(~, sv, W, dt)
        S = obj.voigtToTensorBatch(sv);
        S = S + (S*W - W*S)*dt;
        sv = obj.tensorToVoigtBatch(S);
    end
end
end