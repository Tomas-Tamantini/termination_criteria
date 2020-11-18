function [min_x, min_fun] = lagrange(fun, x0, terminator)
    % lagrange - Use lagrange multipliers to minimize given function
    %
    % Syntax: [min_x, min_fun] = lagrange(fun, x0, terminator)
    %
    % Input: fun - string name of a function file which returns the value
    %              of the objective function and a vector of constraints
    %              (i.e. [f,g,f_grad, jacobian] = fun(x)).
    %        x0 - Initial guess
    %        terminator - Instance of terminator class, with desired criteria
    %
    % Output:
    %   min_x - vector at the optimal solution
    %   min_fun - Optimal value for objective function
    tic;

    current_x = x0;
    [~, constraints, ~, ~] = feval(fun, x0);
    lagrange_mult = zeros(size(constraints));

    nit = 0;
    num_fun_eval = 0;

    while true
        [~, constraints, fun_grad, jacob] = feval(fun, current_x);
        grad_points = fun_grad + jacob' * diag(lagrange_mult) * ones(size(constraints));

        alpha_mult = 0.005; % This is a simple method, just for testing termination criteria, therefore, alpha is *not* optimized

        current_x = current_x - alpha_mult * grad_points;
        lagrange_mult = lagrange_mult + alpha_mult * constraints;

        [new_fun_val, ~, ~, ~] = feval(fun, current_x);

        nit = nit + 1;
        num_fun_eval = num_fun_eval + 2;
        elapsed_time = toc;

        termination_kwargs = struct('nit', nit, 'elapsed_time', elapsed_time, 'fun_value', new_fun_val, 'num_fun_eval', num_fun_eval);

        if terminator.should_terminate(termination_kwargs)
            break
        end

    end

    min_x = current_x;
    [min_fun, ~, ~, ~] = feval(fun, min_x);
end
