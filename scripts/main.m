fprintf('Start new run...\n')

x0 = zeros(2, 1);

% plot = fcontour(@plot_fun);

terminator_kwargs = struct('max_nit', 1000, 'max_elapsed_time', 2);

term = terminator(terminator_kwargs);

[x_sol, f_sol] = lagrange('example_quad', x0, term);

term.print_status();

fprintf('End run. Optimized value: %f\nat:\n', f_sol);
disp(x_sol);

% function value = plot_fun(x, y)
%     [value, ~, ~, ~] = example_quad([x; y]);
% end
