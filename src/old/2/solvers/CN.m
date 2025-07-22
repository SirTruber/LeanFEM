function CN(problem, time)
    xi = 0.5;

    K = problem.time_step * xi * xi * problem.stiffness + 1/problem.time_step * problem.mass;
    if isfield(problem, 'damping')
        K -= xi * problem.damping;
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

        r = problem.load + (problem.mass * 1/problem.time_step * v_p - problem.stiffness * (problem.time_step * xi * (1 - xi) * v_p - u_p);
        if isfield(problem, 'damping')
            r += problem.damping * (1 - xi) * v_p;
        endif

        r(problem.attach) = 0;

        v = K\(K'\r);

        u = u_p + problem.time_step * (xi * v + (1 - xi) * v_p);
    endfor
endfunction
