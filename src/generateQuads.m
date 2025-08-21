function [quads,quads_to_hexas,hexas_to_quads] = generateQuads(hexas)
    a = ...
    [1 2 3 4;...  % Грань 1 (нижняя)
     5 8 7 6;...  % Грань 2 (верхняя)
     1 5 6 2;...  % Грань 3 (передняя)
     4 3 7 8;...  % Грань 4 (задняя)
     2 6 7 3;...  % Грань 5 (правая)
     1 4 8 5];    % Грань 6 (левая)

    quads = reshape(hexas(:,a),[],4); %Собираем все грани гексаэдров
    quads_to_hexas = repelem(1:size(hexas,1),6)';

    [u,ida,idx] = unique(sort(quads,2),"rows"); %Оставляем только уникальные
    count = accumarray(idx,1);

    quads = quads(ida(count == 1),:); % И которые встречаются только один раз

    quads_to_hexas = quads_to_hexas(ida(count == 1));

    hexas_to_quads = []; %TODO Доделать
end
