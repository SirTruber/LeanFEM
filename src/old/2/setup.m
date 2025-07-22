axis equal;
view(30,30);
colormap(turbo(1024));
colorbar;
caxis([0 100])
cd Material;
mat = Steel;
cd ../Element;
el = HM24(mat);
at = find(grid.mesh(:,3) == 0);
at = repelem(3*at,3) + repmat((-2:0)',length(at),1);
cd ../Solver

