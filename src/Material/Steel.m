function obj = Steel()
    rho = 7.8; % 7.8 г/см^3
    E   = UnitConverter.MPa_to_pressure_system(2.1e05);
    nu  = 0.3; 
    obj = Material('steel',rho,E,nu);
    obj.yieldStress = UnitConverter.MPa_to_pressure_system(250);
end