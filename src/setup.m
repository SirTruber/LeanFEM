function setup()
projectRoot = fileparts(mfilename('fullpath'));
srcDir = {
    'Elements'
    'Grid'
    'Material'
    'Problems'
    'Solvers'
    'Utils'
    };

for i =1:length(srcDir)
    dirPath = fullfile(projectRoot,srcDir{i});
    if exist(dirPath,'dir')
        addpath(dirPath)
        %fprintf('Add path: %s\n', dirPath); %Debug only
    else
        %warning('No such dir: %s\n', dirPath);
    end
end
end
