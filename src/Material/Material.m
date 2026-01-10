function obj = Material(name,density,youngModule,poissonRatio)
% Системные величины: сантиметры, микросекунды, граммы
% Производные величины: давление = 1e11 Па = 100 ГПа, сила = 10 МН, 
% момент = 100 КН*м
    obj = struct('name', name, 'density', density, 'youngModule', youngModule, 'poissonRatio',poissonRatio);
            
    obj.firstLame =  obj.poissonRatio * obj.youngModule / (1 - obj.poissonRatio * (1 + 2 * obj.poissonRatio));
    obj.secondLame = 0.5 * obj.youngModule / (1 + obj.poissonRatio);
            
    obj.PwaveSpeed = sqrt((obj.firstLame + 2 * obj.secondLame) / obj.density);
    obj.SwaveSpeed = sqrt(obj.secondLame/obj.density);
end