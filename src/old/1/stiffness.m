function K = stiffnes(elem,mesh)
    step = 24 * 24;
    i_trip = []; %zeros(step * size(elem,1));
    j_trip = [];
    v_trip = [];
    for i=1:size(elem,1)
        tmp = repmat(repelem(3*elem(i,:),3) + repmat(int32(-2:0),1,8),24,1);
        i_trip = [i_trip reshape(tmp,1,[])];
        j_trip = [j_trip reshape(tmp.',1,[])];
        v_trip = [v_trip reshape(ELstiffness(i,elem,mesh),1,[])];
    end
    K = sparse(i_trip,j_trip,v_trip);
end
