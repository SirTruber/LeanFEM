% classdef (Abstract) ElementAssembler < Module
%     properties (Constant)
%         INPUT_DATA = {}
%         OUTPUT_DATA = {'K', 'M'}
%     end
%
%     methods
%         function execute(obj)
%             % Сборка глобальных матриц
%             grid = obj.context.grid;
%             [obj.context.results.K, obj.context.results.M] = assemble_system(grid);
%             disp('Матрицы системы собраны');
%         end
%     end
% end
