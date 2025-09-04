function result = evaluateVonMisesStress(result)
    stress = result.stress;
    result.vonMisesStress = sqrt(0.5 * ((stress.sxx - stress.syy).^2 + (stress.syy - stress.szz).^2 + (stress.szz - stress.sxx).^2 + 6 * (stress.sxy.^2 + stress.syz.^2 + stress.sxz.^2)));
end
