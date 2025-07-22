function geometry(filename_input,filename_output)
[mesh,elem] = meshfile(filename_input);
K = stiffnes(elem,mesh);
q = zeros(3 * size(mesh,1),1);
for i = 1:size(mesh,1)
    if (mesh(i,2) == 1 && (mesh(i,3) >= 4 || mesh(i,3) <= 6))
        q(3*i - 1) = 1/9;
    end
    if (mesh(i,3) == 0 || mesh(i,3) == 10)
        left = 3 * i - 3;
        right = 3 * (size(mesh,1) - i);
        q(left + 1:left+3) = 0;
        K11 = K(1:left,1:left);
        K13 = K(1:left,left+4:end);
        %K31 = K(left + 4:end,1:left);
        K33 = K(left + 4:end,left + 4:end);
        K = [K11 zeros(left,3) K13;
             zeros(3,left) speye(3),zeros(3,right);
             K13' zeros(right,3) K33];
    end
end
displacement = reshape(K \ q,3,[]).';
mesh = mesh + displacement;
savemesh(filename_output,mesh,elem);
%function res = cellVolume(i,elem,mesh)
%    res = tetraVolume(elem(i,[1 3 6 8]),mesh) + ...
%          tetraVolume(elem(i,[1 2 6 3]),mesh) + ...
%          tetraVolume(elem(i,[1 3 8 4]),mesh) + ...
%          tetraVolume(elem(i,[1 6 5 8]),mesh) + ...
%          tetraVolume(elem(i,[3 6 8 7]),mesh);
%end

%function res = tetraVolume(nodes,mesh)
%    V = zeros(3,3);
%    for i = 1:3
%        for j = 1:3
%            V(i,j) = mesh(nodes(i+1),j) - mesh(nodes(1),j);
%        end
%    end
%    res = -1/6 * det(V);
%end
