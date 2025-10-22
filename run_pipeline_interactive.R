if (!require("zoo")) install.packages("zoo", dependencies = TRUE, ask = FALSE)
if (!require("glue")) install.packages("glue", dependencies = TRUE, ask = FALSE)
if (!require("httr2")) install.packages("httr2", dependencies = TRUE, ask = FALSE)
if (!require("fixest")) install.packages("fixest", dependencies = TRUE, ask = FALSE)
if (!require("GGally")) install.packages("GGally", dependencies = TRUE, ask = FALSE)
if (!require("jsonlite")) install.packages("jsonlite", dependencies = TRUE, ask = FALSE)
if (!require("modelsummary")) install.packages("modelsummary", dependencies = TRUE, ask = FALSE)
if (!require("tidyverse")) install.packages("tidyverse", dependencies = TRUE, ask = FALSE)

source("R/data-loading.R")
source("R/data-models.R")

master_data <- load_data()
model_data(data4models=master_data)
