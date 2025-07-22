function K = ELstiffness(ind,elem,mesh)
    E = 2100; %GPa
    nu = 0.3; % 1
    la = E * nu / (1 + nu) / (1 - 2*nu);   %placeholder
    mu = E / (2 + 2*nu);   %remove in full program
    h = 1 * minHigth(ind,elem,mesh);
    imaginary = [ 0  0  0  0;
                  h  h  0  h;
                  0  h  h  0;
                  h  0  h  h;
                  0  h  h  h;
                  h  0  h  0;
                  0  0  0  h;
                  h  h  0  0];
    V = [ones(8,1) mesh(elem(ind,:),:) imaginary];
    d = inv(V);
    d = transpose(d);
    B = zeros(18, 24);
    for k = 0:7
        m = 3 * k +1;
        B(1, m) = d(k+1, 2);
        B(4, m) = d(k+1, 3);
        B(6, m) = d(k+1, 4);
        B(4, m+1) = d(k+1, 2);
        B(2, m+1) = d(k+1, 3);
        B(5, m+1) = d(k+1, 4);
        B(6, m+2) = d(k+1, 2);
        B(5, m+2) = d(k+1, 3);
        B(3, m+2) = d(k+1, 4);
        for l = 0:3
            B(l*3 + 7, m) = d(k+1, l+5);
            B(l*3 + 8, m+1) = d(k+1, l+5);
            B(l*3 + 9, m+2) = d(k+1, l+5);
        end
    end

    C = zeros(18, 18);
    C(1:3,1:3) = la * ones(3) + diag(2 * mu * ones(3,1));
    C(4:18,4:18) = diag(mu * ones(15,1));
 vol = -1/6 * (det([ones(4,1) mesh(elem(ind,[1 3 6 8]),:)]) + det([ones(4,1) mesh(elem(ind,[1 2 6 3]),:)]) + det([ones(4,1) mesh(elem(ind,[1 3 8 4]),:)]) + det([ones(4,1) mesh(elem(ind,[1 6 5 8]),:)]) + det([ones(4,1) mesh(elem(ind,[3 6 8 7]),:)]));
    K = transpose(B) * C * B * vol;
end
