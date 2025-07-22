classdef  NewmarkSolver < Module
    properties (Constant)
        INPUT_DATA = {'K','M','dofs','F','time','time_step'}
        OUTPUT_DATA = {'U','V','A'}
    end
    methods
        function execute(obj, context)
            time_step = context.results('time_step');
            beta = 0.5;
            alpha = 0.25 * (0.5 + beta)^2;
            coeffs = [ 1/alpha/time_step^2;
            beta/alpha/time_step;
               1/alpha/time_step;
             0.5/alpha - 1;
            beta/alpha - 1;
                 0.5 * time_step * (beta/alpha - 2);
                       time_step * (1 - beta);
                  beta*time_step];

            K = problem.stiffness + coeffs(1) * problem.mass;
%     if isfield(problem, 'damping')
%         K += coeffs(2) * problem.damping;
%     endif

    K(problem.attach,:) = 0;
    K(:,problem.attach) = 0;
    K(sub2ind(size(K),problem.attach,problem.attach)) = 1;

    K = chol(K);

    u_p = zeros(3 * n,1);
    v_p = zeros(3 * n,1);
    a_p = zeros(3 * n,1);

    u = zeros(3 * n,1);
    v = zeros(3 * n,1);
    a = problem.mass \ problem.load;

    n = time / problem.time_step;

    for i = 1:n
        a_p = a;
        v_p = v;
        u_p = u;

        r = problem.load + problem.mass * (coeffs(1) * u + coeffs(3) * v + coeffs(4) * a );
        if isfield(problem, 'damping')
            r += problem.damping * (coeffs(2) * u + coeffs(5) * v + coeffs(6) * a);
        endif

        r(problem.attach) = 0;

        u = K\(K'\r);

        a = coeffs(1) * (u - u_p) - coeffs(3) * v_p - coeffs(4) * a_p;
        v = v_p + coeffs(7) * a_p + coeffs(8) * a;
    endfor
        end
    end
end

function Newmark(problem, time)
    beta = 0.5;
    alpha = 0.25 * (0.5 + beta)^2;
    coeffs = [ 1/alpha/problem.time_step^2;
            beta/alpha/problem.time_step;
               1/alpha/problem.time_step;
             0.5/alpha - 1;
            beta/alpha - 1;
                 0.5 * problem.time_step * (beta/alpha - 2);
                       problem.time_step * (1 - beta);
                  beta*problem.time_step];

    K = problem.stiffness + coeffs(1) * problem.mass;
    if isfield(problem, 'damping')
        K += coeffs(2) * problem.damping;
    endif

    K(problem.attach,:) = 0;
    K(:,problem.attach) = 0;
    K(sub2ind(size(K),problem.attach,problem.attach)) = 1;

    K = chol(K);

    u_p = zeros(3 * n,1);
    v_p = zeros(3 * n,1);
    a_p = zeros(3 * n,1);

    u = zeros(3 * n,1);
    v = zeros(3 * n,1);
    a = problem.mass \ problem.load;

    n = time / problem.time_step;

    for i = 1:n
        a_p = a;
        v_p = v;
        u_p = u;

        r = problem.load + problem.mass * (coeffs(1) * u + coeffs(3) * v + coeffs(4) * a );
        if isfield(problem, 'damping')
            r += problem.damping * (coeffs(2) * u + coeffs(5) * v + coeffs(6) * a);
        endif

        r(problem.attach) = 0;

        u = K\(K'\r);

        a = coeffs(1) * (u - u_p) - coeffs(3) * v_p - coeffs(4) * a_p;
        v = v_p + coeffs(7) * a_p + coeffs(8) * a;
    endfor
endfunction
