fprintf('Start new run...\n')

x0 = zeros(2, 1);

% plot = fcontour(@plot_fun);

kkt_params = struct('gradient_benchmark', 1e-2, 'max_sum_penalties', 1e-4, 'max_dual_sum', 1e-4, 'max_slackness', 1e-4);

terminator_kwargs = struct('max_elapsed_time', 2, 'kkt_params', kkt_params);

terminator_kwargs = struct('max_elapsed_time', 2, 'gradient_benchmark', 1e-2);

term = terminator(terminator_kwargs);

[x_sol, f_sol] = lagrange('example_quad', x0, term);

term.print_status();

fprintf('End run. Optimized value: %f\nat:\n', f_sol);
disp(x_sol);

% function value = plot_fun(x, y)
%     [value, ~, ~, ~] = example_quad([x; y]);
% end
