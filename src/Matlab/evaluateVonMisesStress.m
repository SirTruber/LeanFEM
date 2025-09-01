function vonMises = evaluateVonMisesStress(stress)
    vonMises = sqrt(0.5 * ((stress(1,:) - stress(2,:)).^2 + (stress(2,:) - stress(3,:)).^2 + (stress(3,:) - stress(1,:)).^2 + 6 * (stress(4,:).^2 + stress(5,:).^2 + stress(6,:).^2)))';
end
