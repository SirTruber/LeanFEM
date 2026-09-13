function obj = Rubber()
    rho = 1.1; % 1.1 г/см^3
    E   = UnitConverter.MPa_to_pressure_system(4);
    nu  = 0.495; 
    obj = Material('rubber',rho,E,nu);
end