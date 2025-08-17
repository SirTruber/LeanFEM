function exportToFile(data, filename, ext)
    fileID = fopen(filename,"w");
    if ~is_valid_file_id(fileID)
        error('file not found');
    end
    switch lower(ext)
        case '.4ekm'
            write4ekm(fileID, data);
        case '.romanov'
            writeRomanov(fileID, data);
    end
    fclose(fileID);
end

function write4ekm(fileID, data)
    numberOfNodes = rows(data.nodes);
    numberOfHexas = rows(data.hexas);

    fprintf(fileID,'%d\n',nodes_size);
    fprintf(fileID,'%d\n',hexas_size);

    nodesSpec = '%11f%11f%11f\n';
    hexasSpec = '%7d%7d%7d%7d%7d%7d%7d%7d\n';
    for i = 1:nodes_size
        fprintf(fileID, nodesSpec, data.nodes(i,:));
    end
    for i = 1:hexas_size
        fprintf(fileID, hexasSpec, data.hexas(i,:));
    end
end

function writeRomanov(fileID, data)
    numberOfNodes = rows(data.nodes);
    numberOfHexas = rows(data.hexas);

    fprintf(fileID,'%d\n',nodes_size);
    fprintf(fileID,'%d\n',hexas_size);

    nodesSpec = '%d%11f%11f%11f\n';
    hexasSpec = '%d%7d%7d%7d%7d%7d%7d%7d%7d\n';
    for i = 1:nodes_size
        fprintf(fileID, nodesSpec,[i, data.nodes(i,:)]);
    end
    for i = 1:hexas_size
        fprintf(fileID, hexasSpec,[i, data.hexas(i,:)]);
    end
end

%!function filename = setupTestData(testData, format)
%! filename = [tempname(), format];
%! fileID = fopen(filename, 'w');
%! fprintf(fileID, testData);
%! fclose(fileID);
%!endfunction
%!test #1.Корректный экспорт
%!
%! testData = '';
%!
%! filename = setupTestData(testData, '.4ekm');
%! data = importFromFile(filename);
%! exportToFile(filename, data);
%!
%! assert()
%!
%!test #2.Экспорт и импорт
%!
%!  data = testData();
%!
%!
