suppressWarnings(
  suppressMessages(
    library(zoo, quietly = TRUE)
  )
)
library(glue)
library(httr2)
library(jsonlite)
library(modelsummary)
suppressWarnings(
  suppressMessages(
    library("tidyverse", quietly = T)
  )
)

## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Data Resources ----
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

get_data_resources <- function(){
  list(
    c(
      variable = "formal_1",
      desc     = "Percentage of total active workers contributing to social security with regards to economically active population",
      id       = "5cb9e985-5a68-4897-bf70-982671e5d09e",
      source   = "SILAC"
    ),
    c(
      variable = "formal_2",
      desc     = "Percentage of employed workers contributing to social security with regards to employed population",
      id       = "f15acf65-17ce-411e-ba54-e6c16ed4babd",
      source   = "SILAC"
    ),
    c(
      variable = "avg_educ_years",
      desc     = "Average years of schooling of the economically active population",
      id       = "1fc2f526-1013-4792-abc8-0ca417c2b952",
      source   = "SILAC"
    ),
    c(
      variable = "employed_agriculture",
      desc     = "Percentage of employed workers in agricultural sector",
      id       = "cda4b865-c8d0-416c-8716-8f5358357339",
      source   = "SILAC"
    ),
    c(
      variable = "min_wage",
      desc     = "Minimum legal monthly wage, PPP (constant 2011 international $)",
      id       = "180803f8-ddfc-4b8b-938b-2a8ff8ddb073",
      source   = "SILAC"
    ),
    c(
      variable = "gov_exp_educ",
      desc     = "Government expenditure on education as a percentage of GDP (%)",
      id       = "55c1891f-59fa-41ad-b646-664c23d3f879",
      source   = "SILAC"
    ),
    c(
      variable = "rural_pop",
      desc     = "Percentage of population residing in rural areas",
      id       = "fbc9e594-c63f-45af-b694-62397d6de28e",
      source   = "SILAC"
    ),
    c(
      variable = "gdp_per_capita",
      desc     = "GDP (US$ per capita, current prices)",
      id       = "3f49f455-2427-4030-ba8d-df2490615d52",
      source   = "LMW"
    ),
    c(
      variable = "cpi",
      desc     = "CPI (index, period average)",
      id       = "9d2d702d-cd01-4c67-95ab-6538d88a11b9",
      source   = "LMW"
    ),
    c(
      variable = "credit",
      desc     = "Total Credit (real index, period average)",
      id       = "5334c542-a319-4268-b8ae-f89fcda811f9",
      source   = "LMW"
    ),
    c(
      variable = "fdi",
      desc     = "Foreign Direct Investment, Net (% of GDP)",
      id       = "d553e130-37d2-4031-8bfd-5374dfe26a50",
      source   = "LMW"
    )
  )
}


## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Fetch & Wrangle Functions ----
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

download_data <- function(variable_name, resource_id, source){
  print(
    glue("--- Downloading data for variable: {variable_name}")
  )
  
  if (source %in% c("LMW")){
    filters <- list(
      frequency = "Annual"
    )
  }
  if (source %in% c("SILAC")){
    filters <- list(
      area       = "Total",
      quintile   = "Total",
      sex        = "Total",
      age        = "Total",
      ethnicity  = "Total",
      language   = "Total",
      disability = "Total",
      migration  = "Total",
      management = "Total",
      funding    = "Total"
    )
  }
  
  endpoint <- "https://data.iadb.org/api/action/datastore_search"
  response <- request(endpoint) |>
    req_url_query(
      resource_id = resource_id,
      filters = toJSON(filters, auto_unbox = TRUE),
      limit = 10000,
      offset = 0
    ) |>
    req_perform() |> 
    resp_body_json()
  
  df <- response |>
    pluck("result", "records") |>
    map(~ map(.x, ~ if(is.null(.x)) NA else .x)) |>
    map_df(as_tibble)
  
  return(df)
}


clean_data <- function(data, source, variable_name=NULL){
  print(glue("------ Cleaning Downloaded Data..."))
  
  target_countries <- c(
    "ARG", "BOL", "BRA", "COL", "CRI", "DOM", "ECU", "GTM",
    "HND", "MEX", "PAN", "PER", "PRY", "SLV", "URY"
  )
  
  if (source %in% c("LMW")){
    df_cleaned <- data %>% 
      select(
        indicator=name, isoalpha3, year=period, value
      ) %>% 
      mutate(
        indicator = variable_name
      )
  }
  
  if (source %in% c("SILAC")){
    df_cleaned <- data %>% 
      select(
        indicator, isoalpha3, year, value
      ) %>%
      mutate(
        indicator = variable_name
      )
  }
  
  return(
    df_cleaned %>% 
      arrange(isoalpha3, year) %>% 
      filter(
        (isoalpha3 %in% target_countries) &
        (year >= 2000 & year <= 2025)
      )
  )
}


## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Missing Data Handling ----
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

fill_edges <- function(x, max_years = 3) {
  if (all(is.na(x))) return(x)
  
  valid <- which(!is.na(x))
  first_valid <- min(valid)
  last_valid <- max(valid)
  
  avg_change <- mean(diff(x[valid]), na.rm = TRUE)
  
  if (first_valid > 1) {
    leading_nas <- 1:(first_valid - 1)
    fill_these <- leading_nas[leading_nas > (first_valid - max_years - 1)]
    for (i in rev(fill_these)) {
      x[i] <- x[i + 1] - avg_change
    }
  }
  
  if (last_valid < length(x)) {
    trailing_nas <- (last_valid + 1):length(x)
    fill_these <- trailing_nas[trailing_nas < (last_valid + max_years + 1)]
    for (i in fill_these) {
      x[i] <- x[i - 1] + avg_change
    }
  }
  
  return(x)
}

interpol_and_fill <- function(data){
  print(glue("--- Handling Missing Values in Data..."))
  
  data_interpolated <- data %>% 
    group_by(country) %>% 
    mutate(
      across(
        everything(),
        \(x) na.approx(x, maxgap=5, na.rm=FALSE)
      )
    ) %>% 
    filter(
      year >= 2003 & year <= 2022
    )
  
  filled_data <- data_interpolated %>% 
    group_by(country) %>% 
    mutate(
      across(
        everything(),
        \(x) fill_edges(x)
      )
    )
  
  return(filled_data)
}


## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Main Loading Function ----
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

load_data <- function(){
  data_resources <- get_data_resources()
  
  data <- map_dfr(
    data_resources,
    function(resource) {
      
      data_raw <- download_data(
        variable_name = resource["variable"], 
        resource_id = resource["id"],
        source = resource["source"]
      )
      write_csv(
        data_raw, 
        glue("data/api-raw/{resource['variable']}.csv")
      )
      
      data_clean <- clean_data(
        data = data_raw,
        source = resource["source"],
        variable_name = resource["variable"]
      )
      
      return(data_clean)
    }
  )
  
  master_data <- data %>% 
    pivot_wider(
      id_cols = c(isoalpha3, year),
      names_from = indicator,
      values_from = value
    ) %>% 
    rename(country = isoalpha3) %>% 
    arrange(country, year) %>% 
    mutate(
      across(
        !country,
        \(x) as.numeric(x)
      )
    )
  
  write_csv(
    master_data, 
    glue("data/master_data.csv")
  )
  datasummary_skim(
    master_data %>% select(3:13),
    type = "numeric",
    fun_numeric = list(
      Unique = NUnique,
      `Missing Pct.` = PercentMissing, 
      Mean = Mean, SD = SD, Min = Min, Median = Median, Max = Max
    ),
    output = "outputs/summary_table_prehandling.html"
  )
  
  master_data_filled <- interpol_and_fill(data=master_data)
  write_csv(
    master_data_filled, 
    glue("data/master_data_filled.csv")
  )
  
  print(glue("---------------------------"))
  print(glue("DATA LOADING SUCCESSFUL!!"))
  print(glue("---------------------------"))
  
  return(master_data_filled)
}
