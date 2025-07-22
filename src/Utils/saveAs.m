function saveAs(data, filename)
    [~, ~, ext] = fileparts(filename);
    switch lower(ext)
        case '.4ekm'
            IOMesh.save4ekm(data, filename);
        case '.msh'
            IOMesh.saveGmsh(data, filename);
        case '.vtk'
            IOMesh.saveVTK(data, filename);
        otherwise
            error('Unsupported format: %s', ext);
    end
end

function save4ekm(grid,filename)
    fileID = fopen(filename,"w");

    nodes_size = rows(grid.nodes);
    hexas_size = rows(grid.hexas);

    fprintf(fileID,'%d\n',nodes_size);
    fprintf(fileID,'%d\n',hexas_size);

    nodes_spec = '%11f%11f%11f\n';
    hexas_spec = '%7d%7d%7d%7d%7d%7d%7d%7d\n';
    for i = 1:nodes_size
        fprintf(fileID,nodes_spec,grid.nodes(i,:));
    end
    for i = 1:hexas_size
        fprintf(fileID,hexas_spec,grid.hexas(i,:));
    end
    fclose(fileID);
end
