classdef Modal < handle
    % Решатель для модального анализа (свободные колебания без демпфирования)
    properties
        assembler      % объект Assembler
        freeDOF
        dofIndices     % закреплённые степени свободы
        dofValues      % обычно нулевые
        K              % глобальная матрица жёсткости (sparse)
        KG             % глобальная матрица геометрической жёсткости (sparse)
        Keff
        M              % глобальная матрица масс (sparse)
        Meff
        numModes       % число запрашиваемых мод
        omega          % собственные частоты (круговая частота, рад/с)
        phi            % собственные векторы (столбцы)
        frequencies_Hz % частоты в Гц
    end
    methods
        function obj = Modal(assembler, numModes)
            obj.assembler = assembler;
            obj.numModes = numModes;
            obj.K = assembler.stiffness();
            obj.M = assembler.mass();
        end

        function applyBC(obj, dofIndices, dofValues)
            obj.dofIndices = dofIndices(:);

            if nargin < 3 || isempty(dofValues)
                obj.dofValues = zeros(numel(dofIndices), 1);
            else
                obj.dofValues = dofValues(:);
            end
           
            %маска для свободных степеней свободы
            totalDOF = size(obj.K,1);
            obj.freeDOF = setdiff(1:totalDOF, obj.dofIndices);
            
            % Редуцируем матрицы (K и M) только для свободных DOF
            obj.Keff = obj.K(obj.freeDOF, obj.freeDOF);
            obj.Meff = obj.M(obj.freeDOF, obj.freeDOF);
        end

        function prestress(obj, U0)
            sigma_IP = obj.assembler.integrationPointStress(U0);
            obj.KG = obj.assembler.geometricStiffness(sigma_IP);
            K = obj.K - obj.KG;
            obj.Keff = K(obj.freeDOF, obj.freeDOF);
        end

        function mu = robust(obj, U0)
            sigma_IP = obj.assembler.integrationPointStress(U0);
            obj.KG = obj.assembler.geometricStiffness(sigma_IP);
            A = obj.K(obj.freeDOF, obj.freeDOF);
            B = obj.KG(obj.freeDOF, obj.freeDOF);
            opts.tol = 1e-6;
            opts.maxit = 1000;
            [V, D] = eigs(A, B, obj.numModes, "sm", opts);
            
            d = diag(D);
            [mu, idx] = sort(d);
            obj.phi = V(:, idx);
        end

        function solve(obj)
            % Решение обобщённой проблемы собственных значений 
            % Используем eigs для поиска наименьших собственных значений
            % Чтобы получить наименьшие собственные значения (низкие частоты)
            opts.tol = 1e-6;
            opts.maxit = 1000;
            [V, D] = eigs(obj.Keff, obj.Meff, obj.numModes, "sm", opts);
            % Сортировка
            d = diag(D);
            [d, idx] = sort(d);
            obj.omega = sqrt(d);
            obj.phi = V(:, idx);
            
            obj.frequencies_Hz = UnitConverter.freq_system_to_Hz(obj.omega / (2*pi));
        end

        function fullPhi = expandModes(obj)
            % Восстанавливаем полный вектор собственных форм (с нулями на закреплённых DOF)
            totalDOF = size(obj.K,1);
            fullPhi = zeros(totalDOF, obj.numModes);
            fullPhi(obj.freeDOF, :) = obj.phi;
        end
    end
end
