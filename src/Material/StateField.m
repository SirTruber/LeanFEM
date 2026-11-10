classdef StateField
    enumeration
        Stress       % напряжение в мере, определяемой strainInfo.type (Cauchy / P / S)
        EpsP         % пластическая деформация (Voigt, 6)
        Eqpl         % накопленная эквивалентная пластическая деформация (скаляр)
    end
end