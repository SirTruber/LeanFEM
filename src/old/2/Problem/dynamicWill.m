function displacement = dynamicWill(grid,graphic_handle,elem_idx)
    cd ../Material;
    mat = Steel;

    cd ../Element;
    el = HM24(mat);

    q(3 * find(grid.mesh(:,2) == 1 & grid.mesh(:,3) >= 40 & grid.mesh(:,3) <= 60) - 1) = -2 / 450;
    at = find(grid.mesh(:,3) == 0);
    at = repelem(3*at,3) + repmat((-2:0)',length(at),1);

    cd ../Solver;
    solver = Willson(grid,el,at,20);

    n = 12000;
    for i=1:n
        solver = solver.step(q);

        displacement = reshape(solver.u,3,[])';
        set(graphic_handle,"vertices",grid.mesh + displacement);
        set(graphic_handle,"facevertexcdata",c_d);
        drawnow
    end
end
