using ArgParse
using Dates
using JSON
using Logging
using IterTools

RAND_SEED = 1337
DEFALT_CMD = "julia"

function cart_prod_dict(d)
    return Tuple(Dict(zip(keys(d), x)) for x in IterTools.product(values(d)...))
end

function vals_to_str(v)
    if isa(v, Array)
        return join(v, " ")
    else
        return repr(v)
    end
end

function parse_cmd_line()
    s = ArgParseSettings()

    @add_arg_table s begin
        "config"
            help = "Path to config (JSON) file"
            arg_type = String
            required = true
        "--output", "-o"
            help = "Output directory to print commands"
            arg_type = String
            default = "scripts/"
        "--defaults", "-d"
            help = "Path to default json"
            arg_type = String
            default = nothing
        "--bin", "-b"
            help = "Binary name"
            arg_type = String
            default = "exp.jl"
        "--env", "-e"
            help = "Bash environment strings"
            arg_type = String
            default = ""
        "--exp-id"
            help = "Experiment id"
            arg_type = String
            default = "gen-script"
        "--seeds"
            help = "Seeds for random configurations"
            arg_type = AbstractArray{Int}
            default = [1337]
   
    end

    return parse_args(s)
end

function main()
    
    args = parse_cmd_line()
    
    #
    # creating output dirs, if they do not exist
    # keep track of exps via ids or dates
    date_string = Dates.format(now(), "yyyymmdd-HHMMSSs")
    out_path = joinpath(args["output"], "$(args["exp-id"])_$(date_string)")
    mkpath(out_path)

    #
    # setting local logger
    log_path_dir = joinpath(out_path, "logs")
    mkpath(log_path_dir)
    log_path = joinpath(log_path_dir, "log.txt")
    log_io = open(log_path, "w+")
    logger = SimpleLogger(log_io)
    

    #
    # loading default params
    if args["defaults"] != nothing
        defaults = nothing
        open(args["defaults"]) do f
            defaults = JSON.parse(f)
        end
        @info("Loaded defaults: $defaults")
    end

    #
    # check for expected params
    if !haskey(defaults, "cmd")
        defaults["cmd"] = DEFALT_CMD
    end

    #
    # loading exp configs
    config = nothing
    open(args["config"]) do f
       config = JSON.parse(f)
    end
    @info("Loaded configs: $config")

    #
    # cartesian product of dictionaries
    configs = cart_prod_dict(config)

    for (exp_id, c) in enumerate(configs)
        for seed in args["seeds"]
            d = deepcopy(defaults)
            d = merge(d, c)
            @assert haskey(d, "expname")

            #
            # create command string
            cmd = "$(args["env"]) $(d["cmd"]) $(args["bin"]) $(d["expname"])"
            pop!(d, "cmd")
            pop!(d, "expname")

            cmd *= " --exp-id $exp_id "

            cmd *= " --seed $seed "

            for (k, v) in d
                cmd *= " --$(k) $(vals_to_str(v)) "
            end

            println(cmd)

        end
    end
    
end

main()
