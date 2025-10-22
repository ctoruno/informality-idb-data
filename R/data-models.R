library(glue)
library(fixest)
library(GGally)
library(modelsummary)
suppressWarnings(
  suppressMessages(
    library("tidyverse", quietly = T)
  )
)

preload_data <- function(){
  print(
    glue("--- Preloading master data from saved file")
  )
  df <- read_csv("data/master_data_filled.csv", show_col_types = FALSE)
  return(df)
}

model_data <- function(data4models){
  
  fe_models <- list(
    "(I)" = paste(
      "formal_1 ~",
      "log(gdp_per_capita) + avg_educ_years + employed_agriculture +",
      "log(min_wage) + log(cpi)"
    ),
    "(II)" = paste(
      "formal_2 ~",
      "log(gdp_per_capita) + avg_educ_years + employed_agriculture +",
      "log(min_wage) + log(cpi)"
    ),
    "(III)" = paste(
      "formal_1 ~",
      "log(gdp_per_capita) + avg_educ_years + employed_agriculture +",
      "log(min_wage) + log(cpi)",
      "| country + year"
    ),
    "(IV)" = paste(
      "formal_2 ~",
      "log(gdp_per_capita) + avg_educ_years + employed_agriculture +",
      "log(min_wage) + log(cpi)",
      "| country + year"
    ),
    "(IV)" = paste(
      "formal_1 ~",
      "log(gdp_per_capita) + avg_educ_years + employed_agriculture +",
      "log(min_wage) + log(cpi) +",
      "log(lag_credit) + lag_fdi",
      "| country + year"
    ),
    "(VI)" = paste(
      "formal_2 ~",
      "log(gdp_per_capita) + avg_educ_years + employed_agriculture +",
      "log(min_wage) + log(cpi) +",
      "log(lag_credit) + lag_fdi",
      "| country + year"
    )
  )
  
  data4models <- data4models %>% 
    group_by(country) %>% 
    mutate(
      lag_credit = lag(credit, n = 1),
      lag_fdi = lag(fdi, n = 1)
    ) %>% 
    ungroup()
  
  print(
    glue("--- Performing data exploration for regression model")
  )
  features <- data4models %>% 
    select(c(3:11, 14, 15)) %>% 
    mutate(
      log_gdp = log(gdp_per_capita),
      log_min_wage = log(min_wage),
      log_cpi = log(cpi),
      log_lag_credit = log(lag_credit)
    ) %>% 
    select(
      -c(gdp_per_capita, min_wage, cpi, lag_credit)
    )
  
  # Summary Table
  datasummary_skim(
    features,
    type = "numeric",
    fun_numeric = list(
      Unique = NUnique,
      `Missing Pct.` = PercentMissing, 
      Mean = Mean, SD = SD, Min = Min, Median = Median, Max = Max
    ),
    output = "outputs/summary_table.html"
  )
  
  # Pairs Plot
  pairsplot <- ggpairs(
    features,
    columns = 3:11,
    lower = list(continuous = "smooth"),
    upper = list(continuous = "cor")
  )
  ggsave(
    filename = "outputs/pairsplot_features.png",
    plot = pairsplot,
    scale = 3
  )

  
  print(
    glue("--- Fitting regression models")
  )
  
  fe_models_fit <- imap(
    fe_models,
    function(x, model){
      
      fitted_model <- feols(
        as.formula(x),
        data = data4models,
        cluster = ~country
      )
      
      return(fitted_model)
    }
  )
  
  modelsummary(
    fe_models_fit,
    estimate  = "{estimate}{stars}",
    stars     = c("*" = 0.05, "**" = 0.01, "***" = 0.001),
    output    = "outputs/main_results.html"
  )
  
  print(glue("---------------------------"))
  print(glue("DATA MODELLING SUCCESSFUL!!"))
  print(glue("---------------------------"))
}


