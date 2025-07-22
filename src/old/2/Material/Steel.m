function obj = Steel()
    obj.density = 7.8e-09;
    obj.viscosity = 0.0;
    obj.young_module = 2100;
    obj.poisson_ratio = 0.3;

    obj.firstLame =  obj.poisson_ratio * obj.young_module / (1 - obj.poisson_ratio * (1 + 2 * obj.poisson_ratio));
    obj.secondLame = 0.5 * obj.young_module / (1 + obj.poisson_ratio);

    obj.waveSpeed = sqrt((obj.firstLame + 2 * obj.secondLame) / obj.density);
end
