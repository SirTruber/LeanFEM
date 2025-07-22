function obj = ESP()
    obj.density = 1.0e-11;
    obj.viscosity = 0.0;
    obj.young_module = 0.1;
    obj.poisson_ratio = 0.4;

    obj.firstLame =  obj.poisson_ratio * obj.young_module / (1 - obj.poisson_ratio * (1 + 2 * obj.poisson_ratio));
    obj.secondLame = 0.5 * obj.young_module / (1 + obj.poisson_ratio);

    obj.waveSpeed = sqrt((obj.firstLame + 2 * obj.secondLame) / obj.density);
end
