function Willson(problem, time)
    theta = 1.37;
    coeffs = [ 6/(theta * problem.time_step)^2;
               3/(theta * problem.time_step);
               6/(theta * problem.time_step);
            0.5 * theta * problem.time_step;
             6/(theta^2 * problem.time_step)^2;
            -6/(theta^2 * problem.time_step);
          1 - 3/theta;
                    0.5 * problem.time_step;
                          problem.time_step^2 / 6];

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

        r = problem.load + problem.mass * (coeffs(1) * u + coeffs(3) * v + 2 * a );
        if isfield(problem, 'damping')
            r += problem.damping * (coeffs(2) * u + 2 * v + coeffs(4) * a);
        endif

        r(problem.attach) = 0;

        u_t = K\(K'\r);

        a = coeffs(5) * (u_t - u_p) + coeffs(6) * v_p + coeffs(7) * a_p;
        v = v_p + coeffs(8) * (a + a_p);
        u = u_p + problem.time_step * v_p + coeffs(9) * (a + 2 * a_p);
    endfor
end
