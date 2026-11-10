% Линейный изотропный материал с двумя модулями упругоси
classdef IsotropicLinearElastic < AbstractMaterial
properties
    youngModule
    poissonRatio
end
properties(Dependent)
    firstLame
    secondLame
    PwaveSpeed
    SwaveSpeed
end
methods
    function obj = IsotropicLinearElastic(name, rho, E, nu)
        obj.name = name;
        obj.density = rho;
        obj.youngModule = E;
        obj.poissonRatio = nu;
        obj.isLinear = true;
        obj.supportedKinematics = {'small', 'UL'};
        obj.registerField(StateField.Stress, 6);
    end

    function lambda = get.firstLame(obj)
        lambda = obj.poissonRatio * obj.youngModule / ...
            ((1 + obj.poissonRatio) * (1 - 2*obj.poissonRatio));
    end

    function mu = get.secondLame(obj)
        mu = 0.5 * obj.youngModule / (1 + obj.poissonRatio);
    end

    function c = get.PwaveSpeed(obj)
        c = sqrt((obj.firstLame + 2*obj.secondLame)/obj.density);
    end

    function c = get.SwaveSpeed(obj)
        c = sqrt(obj.secondLame/obj.density);
    end

    function D = elasticityMatrix(obj)
        lambda = obj.firstLame;  mu = obj.secondLame;
        D = blkdiag(...
            lambda*ones(3) + 2*mu*eye(3), ...
            mu*eye(3));
    end

    function state_new = updateSmall(obj, state_old, eps)
        sigma = obj.elasticityMatrix() * eps;
        state_new = state_old;
        state_new(obj.layout.(char(StateField.Stress)), :) = sigma;
    end

    function state_new = updateUL(obj, state_old, eps_dot, W, dt)
        if size(eps_dot, 1) ~= 6
            error('%s.updateUL: expected 6-component strain rate', obj.name);
        end
        stressIdx = obj.layout.(char(StateField.Stress));

        S_old = obj.voigtToTensorBatch(state_old(stressIdx, :));      % [3×3×nIP]
        dS_el = obj.voigtToTensorBatch(obj.elasticityMatrix() * eps_dot * dt);
        dS_J  = obj.jaumannBatch(S_old, W, dt);

        S_new = S_old + dS_el + dS_J;
        sig_new = obj.tensorToVoigtBatch(S_new);                      % [6×nIP]

        state_new = state_old;
        state_new(stressIdx, :) = sig_new;
    end
end
end