################################################################################
## Entry point of the diabetes-algo reusable action (see action.yaml)
# 1. Reads the --algorithm argument (command line, or "algorithm" in the YAML
#    config, which takes precedence)
# 2. Runs the corresponding pipeline:
#    - Eastwood (default): analysis/Eastwood/data_process_Eastwood.R
#    - DDSC:               analysis/DDSC/data_process_DDSC.R
################################################################################

algorithm_paths <- list(
  eastwood = c("analysis", "Eastwood", "data_process_Eastwood.R"),
  ddsc     = c("analysis", "DDSC", "data_process_DDSC.R")
)
default_algorithm <- "eastwood"

args <- commandArgs(trailingOnly = TRUE)

# Return the value of a flag-style argument (--name=value or --name value), or NULL
get_arg_value <- function(args, name) {
  flag <- paste0("--", name)
  for (i in seq_along(args)) {
    if (startsWith(args[i], paste0(flag, "="))) {
      return(sub(paste0("^", flag, "="), "", args[i]))
    }
    if (args[i] == flag && i < length(args)) {
      return(args[i + 1])
    }
  }
  NULL
}

# 1. Command line argument
algorithm <- get_arg_value(args, "algorithm")

# 2. "algorithm" in the config parsed from the YAML overrides the command line
#    (same precedence as in the data_process scripts: modifyList(opt, config))
config_json <- get_arg_value(args, "config")
if (!is.null(config_json) && config_json != "") {
  config <- jsonlite::fromJSON(config_json)
  if (!is.null(config$algorithm)) {
    algorithm <- config$algorithm
  }
}

# 3. Otherwise, default
if (is.null(algorithm)) {
  algorithm <- default_algorithm
  print(paste0("No --algorithm provided, using default: ", algorithm))
}

algorithm <- tolower(trimws(as.character(algorithm)))
if (!algorithm %in% names(algorithm_paths)) {
  stop(
    "Invalid --algorithm '", algorithm, "'. Valid options are: ",
    paste(names(algorithm_paths), collapse = ", "), " (case-insensitive)"
  )
}

print(paste0("Running diabetes algorithm: ", algorithm))
source(do.call(here::here, as.list(algorithm_paths[[algorithm]])))
