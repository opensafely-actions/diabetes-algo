################################################################################
## This script does the following:
# 1. Defines the input arguments for the reusable action
# 2. Loads the input data (.csv file)
# 3. Maps the input variables to the reusable action arguments
# 4. Checks if all variables needed for the reusable action are present in the data
# 5. Defines the core dataset with only the variables needed for the algorithm to work
# 6. Double-checks the format of the core variables and runs a few checks
# 7. Re-formats the core variables
# 8. Runs the diabetes algorithm and reduces the 14 input core variables to () output variables
# 9. Merges the () output variables back to the initial dataset by replacing the 21 input core variables
# 10 Save output dataset (data_processed.rds)
################################################################################

print("diabetes-algo version: v0.0.14")

################################################################################
# Import libraries and functions
################################################################################
print("Import libraries")
library('arrow')
library('readr')
library('here')
library('lubridate')
library('dplyr')
library('tidyr')

print("Import diabetes algo function")
source(here::here("analysis", "DDSC", "functions", "fn_diabetes_algorithm.R"))

# check if output sub directory exists, create if not
fs::dir_create(here::here("output/DDSC"))

################################################################################
# Define flag style arguments using the optparse package
################################################################################
library('optparse')
option_list <- list(
  make_option(
    "--df_input",
    type = "character",
    default = "input.csv",
    help = "Input dataset. csv, csv.gz, rds, arrow, or a feather file. Assumed to be within the directory 'output' [default %default]",
    metavar = "filename.csv"
  ),
  make_option(
    "--remove_helper",
    type = "logical",
    default = TRUE,
    help = "Logical, indicating whether all helper variables (tmp_ and step_) are removed [default %default]",
    metavar = "TRUE/FALSE"
  ),
  make_option(
    "--birth_date",
    type = "character",
    default = "birth_date",
    help = "Birth date [default %default]",
    metavar = "YYYY-MM-DD"
  ),
  make_option(
    "--last_observable_date",
    type = "character",
    default = "last_observable_date",
    help = "Last observable date [default %default]",
    metavar = "YYYY-MM-DD"
  ),
  make_option(
    "--t1dm_date",
    type = "character",
    default = "t1dm_date",
    help = "Type 1 DM diagnosis date, from both primary (e.g. https://www.opencodelists.org/codelist/user/hjforbes/type-1-diabetes/674fbd7a/) and secondary (e.g. https://www.opencodelists.org/codelist/user/alainamstutz/type-1-diabetes-secondary-care/5eab6d93/) care [default %default]",
    metavar = "YYYY-MM-DD"
  ),
  make_option(
    "--t1dm_count_num",
    type = "character",
    default = "t1dm_count_num",
    help = "Count of all recorded Type 1 DM diagnosis codes, from both primary and secondary care [default %default]",
    metavar = "t1dm_count_varname"
  ),
  make_option(
    "--t2dm_date",
    type = "character",
    default = "t2dm_date",
    help = "Type 2 DM diagnosis date, from both primary (e.g. https://www.opencodelists.org/codelist/user/hjforbes/type-2-diabetes/3530d710/) and secondary (e.g. https://www.opencodelists.org/codelist/user/alainamstutz/type-2-diabetes-secondary-care/77bae0c8/) care [default %default]",
    metavar = "YYYY-MM-DD"
  ),
  make_option(
    "--t2dm_count_num",
    type = "character",
    default = "t2dm_count_num",
    help = "Count of all recorded Type 2 DM diagnosis codes, from both primary and secondary care [default %default]",
    metavar = "t2dm_count_varname"
  ),
  make_option(
    "--otherdm_date",
    type = "character",
    default = "otherdm_date",
    help = "Other DM diagnosis date, from primary care (e.g. https://www.opencodelists.org/codelist/user/hjforbes/other-or-nonspecific-diabetes/0311f0a6/) only [default %default]",
    metavar = "YYYY-MM-DD"
  ),
  make_option(
    "--nosdm_date",
    type = "character",
    default = "nosdm_date",
    help = "NOS DM diagnosis date, from primary care (e.g. https://www.opencodelists.org/codelist/user/hjforbes/other-or-nonspecific-diabetes/0311f0a6/) only [default %default]",
    metavar = "YYYY-MM-DD"
  ),
  make_option(
    "--two_consecutive_high_hba1c",
    type = "character",
    default = "two_consecutive_high_hba1c",
    help = "Two consecutive high hba1c , from primary care only [default %default]",
    metavar = "two_consecutive_high_hba1c_varname"
  ),
  make_option(
    "--insulin_date",
    type = "character",
    default = "insulin_date",
    help = "Insulin drug date variable, from primary care (e.g. https://www.opencodelists.org/codelist/opensafely/insulin-medication/2020-04-26/) only [default %default]",
    metavar = "YYYY-MM-DD"
  ),
  make_option(
    "--last_insulin_date",
    type = "character",
    default = "last_insulin_date",
    help = "Last insulin date, from primary care (e.g. https://www.opencodelists.org/codelist/opensafely/insulin-medication/2020-04-26/) only [default %default]",
    metavar = "YYYY-MM-DD"
  ),
  make_option(
    "--antidiabetic_drug_date",
    type = "character",
    default = "antidiabetic_drug_date",
    help = "First antidiabetic drug date, from primary care (e.g. https://www.opencodelists.org/codelist/opensafely/antidiabetic-drugs/2020-07-16/) only [default %default]",
    metavar = "YYYY-MM-DD"
  ),
  make_option(
    "--diabetes_medication_date",
    type = "character",
    default = "diabetes_medication_date",
    help = "First antidiabetic drug date, i.e. minimum of insulin_date and antidiabetic_drug_date [default %default]",
    metavar = "YYYY-MM-DD"
  ),
  make_option(
    "--first_diabetes_diag_or_high_hba1c_date",
    type = "character",
    default = "first_diabetes_diag_or_high_hba1c_date",
    help = "First diabetes diagnosis date variable [default %default]",
    metavar = "YYYY-MM-DD"
  ),
  make_option(
    "--df_output",
    type = "character",
    default = "data_processed.csv.gz",
    help = "Output dataset. csv.gz or rds file. This is assumed to be added to the directory 'output' [default %default]",
    metavar = "filename.csv.gz"
  ),
  make_option(
    "--config",
    type = "character",
    default = "",
    help = "Config parsed from the YAML",
    metavar = ""
  )
)
opt_parser <- OptionParser(
  usage = "diabetes-algo:[version] [options]",
  option_list = option_list
)
opt <- parse_args(opt_parser)

# Parse the config from YAML
if (opt$config != "") {
  config <- jsonlite::fromJSON(opt$config)
  opt <- modifyList(opt, config)
}

################################################################################
# Record input arguments
################################################################################
print("Record input arguments")
record_args <- data.frame(
  argument = names(opt),
  value = unlist(opt),
  stringsAsFactors = FALSE
)
row.names(record_args) <- NULL

################################################################################
# Load data
################################################################################
print("Load data")
if (grepl(".csv.gz", opt$df_input)) {
  R.utils::gunzip(paste0("output/", opt$df_input), remove = FALSE)
  opt$df_input <- substr(opt$df_input, 1, nchar(opt$df_input) - 3)
}
if (grepl(".csv", opt$df_input)) {
  data <- readr::read_csv(paste0("output/", opt$df_input))
} else if (grepl(".rds", opt$df_input)) {
  data <- readr::read_rds(paste0("output/", opt$df_input))
} else if (grepl(".feather", opt$df_input) || grepl(".arrow", opt$df_input)) {
  data <- arrow::read_feather(paste0("output/", opt$df_input))
}
print(summary(data))

################################################################################
# Map user column names to standardized argument names, double-check, and extract core data
################################################################################
print("Map user variable names")
column_mapping <- list(
  birth_date = opt$birth_date,
  last_observable_date = opt$last_observable_date,
  t1dm_date = opt$t1dm_date,
  t1dm_count_num = opt$t1dm_count_num,
  t2dm_date = opt$t2dm_date,
  t2dm_count_num = opt$t2dm_count_num,
  otherdm_date = opt$otherdm_date,
  nosdm_date = opt$nosdm_date,
  two_consecutive_high_hba1c = opt$two_consecutive_high_hba1c,
  insulin_date = opt$insulin_date,
  last_insulin_date = opt$last_insulin_date,
  antidiabetic_drug_date = opt$antidiabetic_drug_date,
  diabetes_medication_date = opt$diabetes_medication_date,
  first_diabetes_diag_or_high_hba1c_date = opt$first_diabetes_diag_or_high_hba1c_date
)

print("Double-check if all required variables part of user data")
# whether all the columns specified by the user in their command-line arguments actually exist in their data
missing_columns <- setdiff(unlist(column_mapping), colnames(data))
if (length(missing_columns) > 0) {
  stop(paste(
    "The following columns are missing in the data:",
    paste(missing_columns, collapse = ", ")
  ))
}

print("Extract core data and patient_id")
core <- data[c("patient_id", unlist(column_mapping))]


################################################################################
# Double-check the imported core variables
################################################################################
print("Check the date variables")
date_columns <- names(core)[grepl("_date$", names(core))]
# Check for invalid date formats while allowing NA values
invalid_dates <- sapply(core[date_columns], function(col) {
  parsed_dates <- as.Date(col, format = "%Y-%m-%d")
  # Identify non-NA values that failed conversion
  invalid_values <- !is.na(col) & is.na(parsed_dates)
  any(invalid_values) # TRUE if any invalid non-NA values are found
})
# Error message
if (any(invalid_dates)) {
  stop(paste(
    "The following date columns contain invalid date formats:",
    paste(names(invalid_dates)[invalid_dates], collapse = ", ")
  ))
}
print(
  "validation passed: all date values are coded as dates in the format %Y-%m-%d"
)

print("Check the numeric variables")
numeric_columns <- names(core)[grepl("_num$", names(core))]
# Check for invalid numeric values while allowing NA
invalid_numerics <- sapply(core[numeric_columns], function(col) {
  # Check if non-NA values can be converted to numeric
  invalid_values <- !is.na(col) & is.na(suppressWarnings(as.numeric(col)))
  any(invalid_values) # TRUE if any invalid non-NA values are found
})
# Error message
if (any(invalid_numerics)) {
  stop(paste(
    "The following numeric columns contain invalid numeric values:",
    paste(names(invalid_numerics)[invalid_numerics], collapse = ", ")
  ))
}
print("validation passed: all numeric values are coded as numeric")


################################################################################
# Reformat the imported core variables
################################################################################
print("Reformat the imported core variables")
core <- core %>%
  mutate(
    across(
      all_of(date_columns),
      ~ floor_date(as.Date(., format = "%Y-%m-%d"), unit = "days")
    ),
    across(contains('_num'), ~ as.numeric(.)),
    across(contains('_cat'), ~ as.factor(.))
  )

################################################################################
# Apply the diabetes algorithm
################################################################################
print("Apply the diabetes algorithm")
core <- fn_diabetes_algorithm(core, column_mapping)

################################################################################
# Merge the core back to the user data
################################################################################
if (opt$remove_helper == TRUE) {
  print("Remove helper variables")
  core <- core %>%
    dplyr::select(-contains("tmp"), -contains("step"))
}

# Exclude first the core variables from users' input data since they are in both datasets (core and data)
non_core <- data[setdiff(names(data), c(unlist(column_mapping)))]
data_processed <- merge(non_core, core, by = "patient_id", all.x = TRUE)
data_processed_new <- data_processed
################################################################################
# Save output
################################################################################
print("Save output")
write_rds(data_processed, paste0("output/DDSC/", opt$df_output))
write_csv(
  data_processed,
  here::here("output/DDSC", paste0(opt$df_output)),
  na = ""
) # important to specify (na = ""), otherwise @table_from_file("output/DDSC/data/data_processed.csv.gz") doesn't work (accepts empty or a date, but not NA)
