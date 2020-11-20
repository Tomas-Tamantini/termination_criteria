classdef terminator < handle
    %TERMINATOR Class to terminate optimization loops
    %   User defines the criterion (or criteria) which
    %   will determine when an optimization iteration
    %   is to be terminated

    properties
        status
        minimize
        % Trivial conditions
        nit
        elapsed_time
        fun_val
        num_eval
        %KKT Conditions
        kkt_params

    end

    methods

        function obj = terminator(kwargs)
            %TERMINATOR Construct an instance of this class
            %   Initialize new terminator with keyword arguments, given as struct
            %   The struct fields are all optional. They are:
            %       1. minimize [bool]: Indicates whether it is a minimization problem (DEFAULT = true)
            %       2. nit [int]: Maximum number of iterations
            %       3. elapsed_time [float]: Maximum elapsed time allowed
            %       4. fun_val [float]: Benchmark value, to terminate solver if function goes below it (or above it, if maximizing)
            %       5. num_eval [int]: Maximum number of function evaluations allowed
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

            % TODO: Raise exception on unknown parameter
            obj.minimize = true;

            if isfield(kwargs, 'minimize')
                obj.minimize = kwargs.minimize;
            end

            props = properties(obj);

            for prop_index = 1:length(props)
                prop_name = props{prop_index};

                if prop_name == "status" || prop_name == "minimize"
                    continue
                end

                obj.(prop_name) = terminator.field_from_name(prop_name, kwargs);

            end

            % Check if user passed KKT conditions not wrapped inside their own struct
            for prop_name = {'gradient', 'max_sum_penalties', 'max_dual_sum', 'max_slackness'}

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

            if obj.nit.is_active && isfield(kwargs, 'nit') && (kwargs.nit >= obj.nit.value)
                response = true;
                terminate_reason = "reached maximum number of iterations";

            elseif obj.elapsed_time.is_active && isfield(kwargs, 'elapsed_time') && kwargs.elapsed_time >= obj.elapsed_time.value
                response = true;
                terminate_reason = "reached maximum allowed ellapsed time";

            elseif obj.fun_val.is_active && isfield(kwargs, 'fun_val')

                if (obj.minimize && (kwargs.fun_val <= obj.fun_val.value)) || (~obj.minimize && (kwargs.fun_val >= obj.fun_val.value))
                    response = true;
                    terminate_reason = "reached benchmark function value";
                end

            elseif obj.num_eval.is_active && isfield(kwargs, 'num_eval') && kwargs.num_eval >= obj.num_eval.value
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
            if isfield(obj.kkt_params.value, 'gradient')

                if ~isfield(current_kkt_params, 'gradient')
                    meets_all_conditions = false;
                    return
                end

                if obj.kkt_params.value.gradient < current_kkt_params.gradient
                    meets_all_conditions = false;
                    return
                end

                at_least_one_test = true;

            end

            % 2nd condition - Primal feasibility
            if isfield(obj.kkt_params.value, 'primal_feas')

                if ~isfield(current_kkt_params, 'primal_feas')
                    meets_all_conditions = false;
                    return
                end

                if obj.kkt_params.value.primal_feas < current_kkt_params.primal_feas
                    meets_all_conditions = false;
                    return
                end

                at_least_one_test = true;

            end

            %3rd condition - Dual feasibility
            if isfield(obj.kkt_params.value, 'dual_feas')

                if ~isfield(current_kkt_params, 'dual_feas')
                    meets_all_conditions = false;
                    return
                end

                if obj.kkt_params.value.dual_feas < current_kkt_params.dual_feas
                    meets_all_conditions = false;
                    return
                end

                at_least_one_test = true;

            end

            %4th condition - Complementary slackness
            if isfield(obj.kkt_params.value, 'slackness')

                if ~isfield(current_kkt_params, 'slackness')
                    meets_all_conditions = false;
                    return
                end

                if obj.kkt_params.value.slackness < current_kkt_params.slackness
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
