## ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Script:            Entry point
## Author(s):         Carlos Toruno
## Creation date:     October 20, 2025
## ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Define command line options
option_list <- list(
  optparse::make_option(
    c("--data"),
    action  = "store_true",
    default = FALSE,
    help    = "Perform data loading routines"
  ),
  optparse::make_option(
    c("--model"),
    action  = "store_true",
    default = FALSE,
    help    = "Perform data modelling routines"
  ),
  optparse::make_option(
    c("--all"),
    action  = "store_true",
    default = FALSE,
    help    = "Perform end-to-end routine"
  )
)

# Parse command line options
opt_parser <- optparse::OptionParser(
  option_list     = option_list,
  add_help_option = TRUE,
  description     = "R project for the 2025 Thailand GPP Report"
)
opt <- optparse::parse_args(opt_parser)


# Entry Point Main Function
main <- function(){
  
  if (!require("renv")) install.packages("renv")
  renv::activate()
  renv::restore(prompt = FALSE)  # Install dependencies from renv.lock
  
  if (opt$data | opt$all){
    source("R/data-loading.R")
    master_data <- load_data()
  }
  
  if (opt$model | opt$all){
    source("R/data-models.R")
    if (!(opt$data)){
      master_data <- preload_data()
    }
    model_data(data4models=master_data)
  }
}


if(!interactive()){
  main()
  quit(save = "no", status = 0)
}