fprintf('Start new run...\n')

x0 = zeros(2, 1);

% plot = fcontour(@plot_fun);

kkt_params = struct('gradient_benchmark', 10, 'max_sum_penalties', .0001);

terminator_kwargs = struct('max_elapsed_time', 2, 'kkt_params', kkt_params);

term = terminator(terminator_kwargs);

[x_sol, f_sol] = lagrange('example_quad', x0, term);

term.print_status();

fprintf('End run. Optimized value: %f\nat:\n', f_sol);
disp(x_sol);

% function value = plot_fun(x, y)
%     [value, ~, ~, ~] = example_quad([x; y]);
% end
