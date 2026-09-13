function obj = Plumbum()
    rho = 7.8; % 7.8 г/см^3
    E   = UnitConverter.MPa_to_pressure_system(0.17e05);
    nu  = 0.42; 
    obj = Material('plumbum',rho,E,nu); % \rho = 7.8 г/см^3, E = 0.17e05 МПа, \nu = 0.42
    obj.yieldStress = UnitConverter.MPa_to_pressure_system(10); % 10 МПа
end