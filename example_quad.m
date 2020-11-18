function [fun, g, grad, jacob] = example_quad(x)
    % example_quad - Example function to test termination criteria
    %
    % Syntax: [fun, g, grad, jacob] = example_quad(x)
    %
    % Objective function: f = sum(i*(xi-1)²)
    % Restrictions:
    %   g1, g2 <= 0 with:
    %       g1 = -1 + x² + y² + z² + ...
    %       g2 = -0.5 + (x-1)² + y² + z² + ...
    % Output:
    %   fun - Objective function at given point
    %   g - Restriction values at given point
    %   grad - Gradient of objective function at given point
    %   jacob - Jacobian matrix of restrictions [g1x g1y ; g2x g2y]
    %
    % For 2-D, the minimum is f = (47 - 16*sqrt7)/16 = 0.2917
    %                         at x = 3/4 and y = sqrt(7)/4 = 0.6614

    dif = x - 1;
    A = diag(1:length(x));

    fun = dif' * A * dif;

    g(1, 1) = x' * x - 1;
    shifted_x = x;
    shifted_x(1, 1) = shifted_x(1, 1) - 1;
    g(2, 1) = shifted_x' * shifted_x - 0.5;

    grad = 2 * A * dif;

    jacob = 2 * x';
    jacob = [jacob; 2 * shifted_x'];

end
