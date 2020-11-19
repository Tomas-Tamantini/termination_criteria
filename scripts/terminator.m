classdef terminator < handle
    %TERMINATOR Class to terminate optimization loops
    %   User defines the criterion (or criteria) which
    %   will determine when an optimization iteration
    %   is to be terminated

    properties
        status
        minimize
        % Trivial conditions
        max_nit
        max_elapsed_time
        benchmark
        max_fun_eval
        %KKT Conditions
        kkt_params

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
            %       6. kkt_params [struct]: Structure containing the tolerance of KKT conditions. Each of the field in the struct
            %                               can also be passed as a field in the original struct, no need to be wrapped in this
            %                               substruct. These fields are:
            %                               6a. gradient_benchmark [float]: Maximum allowed lagrangian gradient
            %                               6b. max_sum_penalties [float]: Maximum allowed sum of constraint penalties
            %                               6c. max_dual_sum [float]: Maximum allowed sum of negative lagrangian multipliers (absolute value)
            %                               6d. max_slackness [float]: Maximum allowed sum of each constraint times its lagrangian multiplier
            %   Example:
            %       terminator_kwargs = struct('max_nit', 2, 'max_elapsed_time', 3, 'benchmark', 0.01);
            %       term = terminator(terminator_kwargs);
            %   The variable 'term' can now be used inside a solver
            obj.minimize = true;

            if isfield(kwargs, 'minimize')
                obj.minimize = kwargs.minimize;
            end

            for prop_name = {'max_nit', 'max_elapsed_time', 'benchmark', 'max_fun_eval', 'kkt_params'}
                obj.(prop_name{1}) = terminator.field_from_name(prop_name{1}, kwargs);
            end

            % Check if user passed KKT conditions not wrapped inside their own struct
            for prop_name = {'gradient_benchmark', 'max_sum_penalties', 'max_dual_sum', 'max_slackness'}

                if isfield(kwargs, prop_name{1})

                    if ~obj.kkt_params.is_active
                        obj.kkt_params.is_active = true;
                        obj.kkt_params.value = struct();
                    end

                    obj.kkt_params.value.(prop_name{1}) = kwargs.(prop_name{1});
                end

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
            %           5. gradient [float]: Size of lagrangian gradient at that point
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

            elseif obj.kkt_params.is_active && isfield(kwargs, 'kkt_params')

                if obj.passes_kkt_conditions(kwargs.kkt_params)
                    response = true;
                    terminate_reason = "current point meets all kkt conditions to precision set by user";
                end

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

    methods (Access = private)

        function meets_all_conditions = passes_kkt_conditions(obj, current_kkt_params)
            meets_all_conditions = true;
            at_least_one_test = false;
            % 1st conditon - Stationarity
            if isfield(obj.kkt_params.value, 'gradient_benchmark')

                if ~isfield(current_kkt_params, 'gradient')
                    meets_all_conditions = false;
                    return
                end

                if obj.kkt_params.value.gradient_benchmark < current_kkt_params.gradient
                    meets_all_conditions = false;
                    return
                end

                at_least_one_test = true;

            end

            % 2nd condition - Primal feasibility
            if isfield(obj.kkt_params.value, 'max_sum_penalties')

                if ~isfield(current_kkt_params, 'sum_penalties')
                    meets_all_conditions = false;
                    return
                end

                if obj.kkt_params.value.max_sum_penalties < current_kkt_params.sum_penalties
                    meets_all_conditions = false;
                    return
                end

                at_least_one_test = true;

            end

            %3rd condition - Dual feasibility
            if isfield(obj.kkt_params.value, 'max_dual_sum')

                if ~isfield(current_kkt_params, 'dual_sum')
                    meets_all_conditions = false;
                    return
                end

                if obj.kkt_params.value.max_dual_sum < current_kkt_params.dual_sum
                    meets_all_conditions = false;
                    return
                end

                at_least_one_test = true;

            end

            %4th condition - Complementary slackness
            if isfield(obj.kkt_params.value, 'max_slackness')

                if ~isfield(current_kkt_params, 'slackness')
                    meets_all_conditions = false;
                    return
                end

                if obj.kkt_params.value.max_slackness < current_kkt_params.slackness
                    meets_all_conditions = false;
                    return
                end

                at_least_one_test = true;

            end

            if ~at_least_one_test
                meets_all_conditions = false;
                return
            end

        end

    end

end
