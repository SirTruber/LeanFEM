function __init__()
    pkg_dir = fileparts(mfilename('fullpath'));

    addpath(fullfile(pkg_dir, 'src'));
    addpath(fullfile(pkg_dir, 'src/Element'));
    addpath(fullfile(pkg_dir, 'src/Solver'));
    addpath(fullfile(pkg_dir, 'src/Utils'));
    addpath(fullfile(pkg_dir, 'src/Vizual'));

    disp('FEMbrium: все функции загружены в глобальную область видимости');
end
