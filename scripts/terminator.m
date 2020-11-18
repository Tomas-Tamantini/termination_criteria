classdef terminator < handle
    %TERMINATOR Class to terminate optimization loops
    %   User defines the criterion (or criteria) which
    %   will determine when an optimization iteration
    %   is to be terminated

    properties
        minimize
        max_nit
        max_elapsed_time
        benchmark
        max_fun_eval
        status
    end

    methods

        function obj = terminator(kwargs)
            %TERMINATOR Construct an instance of this class
            %   Initialize new terminator with keyword arguments, given as struct
            %   The struct fields are all optional. They are:
            %       1. minimize [bool]: Indicates whether it is a minimization problem (DEFAULT = true)
            %       2. max_nit [int]: Maximum number of iterations
            %       3. max_elapsed_time [float]: Maximum elapsed time allowed
            %       4. benchmark [float]: Benchmark value, to terminate solver if function goes below it (or above it, if maximizing)
            %       5. max_fun_eval [int]: Maximum number of function evaluations allowed
            %   Example:
            %       terminator_kwargs = struct('max_nit', 2, 'max_elapsed_time', 3, 'benchmark', 0.01);
            %       term = terminator(terminator_kwargs);
            %   The variable 'term' can now be used inside a solver
            obj.minimize = true;

            if isfield(kwargs, 'minimize')
                obj.minimize = kwargs.minimize;
            end

            for prop_name = {'max_nit', 'max_elapsed_time', 'benchmark', 'max_fun_eval'}
                obj.(prop_name{1}) = terminator.field_from_name(prop_name{1}, kwargs);
            end

        end

        function response = should_terminate(obj, kwargs)
            %should_terminate Returns boolean indicating whether optimization loop should terminate
            %INPUT: Struct containing keyword arguments that will indicate whether program should terminate.
            %       The input fields are all optional. They are:
            %           1. nit [int]: Current number of iterations
            %           2. elapsed_time [float]: Total elapsed time since start of iteration
            %           3. fun_value [float]: Function value at current iteration
            %           4. num_fun_eval [int]: Number of function evaluations that happened so far
            response = false;

            if obj.max_nit.is_active && isfield(kwargs, 'nit') && (kwargs.nit >= obj.max_nit.value)
                response = true;
                terminate_reason = "reached maximum number of iterations";

            elseif obj.max_elapsed_time.is_active && isfield(kwargs, 'elapsed_time') && kwargs.elapsed_time >= obj.max_elapsed_time.value
                response = true;
                terminate_reason = "reached maximum allowed ellapsed time";

            elseif obj.benchmark.is_active && isfield(kwargs, 'fun_value')

                if (obj.minimize && (kwargs.fun_value <= obj.benchmark.value)) || (~obj.minimize && (kwargs.fun_value >= obj.benchmark.value))
                    response = true;
                    terminate_reason = "reached benchmark value";
                end

            elseif obj.max_fun_eval.is_active && isfield(kwargs, 'num_fun_eval') && kwargs.num_fun_eval >= obj.max_fun_eval.value
                response = true;
                terminate_reason = "reached maximum number of function evaluations";
            end

            if response
                obj.status = strcat("Reason for termination: ", terminate_reason, "\n");
                return
            end

        end

        function print_status(obj)
            fprintf(obj.status)
        end

    end

    methods (Static)

        function struct_field = field_from_name(name, kwargs)

            if isfield(kwargs, name)
                struct_field = struct('is_active', true, 'value', kwargs.(name));
            else
                struct_field = struct('is_active', false, 'value', 0);
            end

            return
        end

    end

end
