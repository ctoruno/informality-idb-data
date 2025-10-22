if (!require("renv")) install.packages("renv")
renv::activate()
renv::restore(prompt = FALSE)

source("R/data-loading.R")
source("R/data-models.R")

master_data <- load_data()
model_data(data4models=master_data)
