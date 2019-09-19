using ArgParse
using Dates
using JSON
using Logging

function parse_cmd_line()
    s = ArgParseSettings()

    @add_arg_table s begin
        "dataset"
            help = "Dataset name"
            required = true
        "--output", "-o"
            help = "Output directory"
            arg_type = String
            default = "exp/"
        "--exp-id"
            help = "Experiment id"
            arg_type = String
            default = nothing
        "--seed"
            help = "Seed for random generation"
            arg_type = Int
            default = 1337
        "--verbose", "-v"
            help = "Verbosity level for logger"
            arg_type = Int
            default = 1
        "--flag"
            help = "an option without argument, i.e. a flag"
            action = :store_true
        
    end

    return parse_args(s)
end

function main()
    
    args = parse_cmd_line()
    
    #
    # creating output dirs, if they do not exist
    # keep track of exps via ids or dates
    date_string = Dates.format(now(), "yyyymmdd-HHMMSSs")
    dataset_name = args["dataset"]

    out_path = nothing
    if args["exp-id"] != nothing
        out_path = joinpath(args["output"], args["exp_id"])
    else
        out_path = joinpath(args["output"], "$(dataset_name)_$(date_string)")
    end
    mkpath(out_path)

    
    #
    # setting local logger
    log_path_dir = joinpath(out_path, "logs")
    mkpath(log_path_dir)
    log_path = joinpath(log_path_dir, "log.txt")
    log_io = open(log_path, "w+")
    if args["verbose"] == 1
        log_level = Logging.Info
    elseif args["verbose"] > 1
        log_level = Logging.Debug
    end
    logger = SimpleLogger(log_io, log_level)
    #
    # and sync global one
    global_logger(logger)


    #
    # saving parameter configurations via json
    args_out_path = joinpath(out_path, "args.json")
    open(args_out_path,"w") do f 
        JSON.print(f, args)
    end
    args_str = join(["$a\t=>\t$repr(v)" for (a, v) in args], "\n")
    @info("Starting with arguments $args_str")
end

main()
