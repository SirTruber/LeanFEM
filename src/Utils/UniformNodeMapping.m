% Самый простой способ отображения - узлы ячеек совпадают с узлами конечных элементов.
% Для ажурных и элементов с дополнительными узлами нужно проводить дополнительное отображение.
classdef UniformNodeMapping
    methods
        function [i_glob, j_glob, totalDOF] = globalIndices(obj, dofPerNode, elements, numNodes)
            numElements = size(elements, 2);
            numNodesPerElem = size(elements, 1);
            dofPerElem = dofPerNode * numNodesPerElem;
            totalDOF = dofPerNode * numNodes;

            ij = dofPerNode * repelem(elements, dofPerNode, 1) - ...
                 repmat(int32(dofPerNode-1:-1:0)', numNodesPerElem, numElements);
            [i,j] = ndgrid(1:dofPerElem, 1:dofPerElem);
            i_glob = ij(i(:), :);
            j_glob = ij(j(:), :);
        end
    end
end
