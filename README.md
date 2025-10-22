# Informality and Macroeconomic Factors

## Research Question
**Do macroeconomic factors explain the emergence of informality as a social outcome?**

This project investigates the relationship between macroeconomic indicators and labor market informality across Latin American countries using panel data from the Inter-American Development Bank (IDB) DATA API.

## Project Overview

This research analyzes how various macroeconomic factors (GDP per capita, inflation, minimum wage, education, credit access, foreign direct investment, etc.) influence labor market formality rates in 15 Latin American countries over the period 2003-2022. The project employs fixed effects regression models with country and time fixed effects to control for unobserved heterogeneity.

The analysis uses two measures of formality:
1. Percentage of economically active workers contributing to social security
2. Percentage of employed workers contributing to social security

GitHub repository: https://github.com/ctoruno/informality-idb-data

## Project Structure

```
informality-idb-data/
├── data/
│   ├── api-raw/                    # Raw data files from IDB DATA API
│   ├── master_data.csv             # Merged dataset (before imputation)
│   └── master_data_filled.csv      # Final dataset (after missing value handling)
├── outputs/                        # Tables and figures
│   ├── summary_table_prehandling.html
│   ├── summary_table.html
│   ├── pairsplot_features.png
│   └── main_results.html
├── R/
│   ├── data-loading.R              # Data fetching and preprocessing module
│   └── data-models.R               # Econometric modeling module
├── renv/                           # R package management
├── renv.lock                       # Package dependencies
├── informality-idb-data.Rproj      # RStudio project file
├── main.R                          # Main entry point (command-line execution)
└── run_pipeline_interactive.R      # Interactive execution script (via RStudio)
```

## Prerequisites

### Required Software
- **R** version 4.4.1 or higher ([Download R](https://cran.r-project.org/))
- **RStudio** (recommended ONLY for interactive execution) ([Download RStudio](https://posit.co/download/rstudio-desktop/))
- **Git** (optional, only if cloning from GitHub) ([Download Git](https://git-scm.com/downloads))

### Important Note for Windows Users
Windows users may need to add the R binary to their PATH environment variable. The exact location depends on your installation, but is typically:
```
C:\Program Files\R\R-4.4.1\bin
```

## Installation

### Option 1: Clone from GitHub (Recommended)
```bash
git clone https://github.com/ctoruno/informality-idb-data.git
cd informality-idb-data
```

### Option 2: Download ZIP
1. Download and extract the project ZIP file
2. Open a terminal/command prompt in the extracted folder

## How to Run

The project uses `renv` for package management, which will automatically restore all required dependencies on first run.

### Command-Line Execution

#### Run Complete Pipeline (Data Loading + Modeling)
```bash
Rscript main.R --all
```

#### Run Data Loading Only
```bash
Rscript main.R --data
```

#### Run Modeling Only (requires existing data)
```bash
Rscript main.R --model
```

### Interactive Execution via RStudio

If you encounter issues running R scripts from the command line (e.g., R binary not found, sudo rights required, or path configuration issues):

1. Open `run_pipeline_interactive.R` in RStudio
2. Run the entire script (Ctrl/Cmd + Shift + Enter)

This method automatically checks for and installs missing packages, then executes the complete pipeline equivalent to `Rscript main.R --all`.

## Key Files Explained

### `main.R`
**Main Entry Point (Command-Line)**
- Activates and restores the `renv` environment to ensure all package dependencies are installed
- Parses command-line arguments (`--data`, `--model`, `--all`)
- Orchestrates the execution pipeline by sourcing and calling functions from the R modules
- Provides modular execution: users can run data loading and modeling independently or together
- Only executes when run non-interactively (from command line), preventing accidental execution when sourced

### `R/data-loading.R`
**Data Acquisition and Preprocessing Module**
- Defines all data resources to be fetched from the IDB DATA API (SILAC and LMW databases)
- Downloads raw data for 11 variables across 15 Latin American countries (2000-2025)
- Cleans and standardizes data formats from different API sources
- Handles missing values through:
  - Linear interpolation for gaps up to 5 years
  - Edge filling for leading/trailing missing values (up to 3 years)
- Generates two datasets:
  - `master_data.csv`: Raw merged data before imputation
  - `master_data_filled.csv`: Final dataset with missing values handled
- Produces preliminary summary statistics (saved in `outputs/`)
- Filters data to focus on years 2003-2022 for consistent panel structure

### `R/data-models.R`
**Econometric Analysis Module**
- Loads preprocessed data (can preload from saved files if data loading was skipped)
- Creates lagged variables for credit and FDI to address endogeneity concerns
- Specifies six regression models with varying specifications:
  - Models I-II: Pooled OLS
  - Models III-IV: Country and year fixed effects
  - Models V-VI: Full specification with financial variables and fixed effects
- Performs exploratory data analysis:
  - Summary statistics for all model features
  - Correlation matrix and pairs plots
- Estimates all models using `fixest::feols()` with clustered standard errors at country level
- Generates publication-ready regression tables (HTML format)
- Saves all outputs (tables and figures) to the `outputs/` directory

### `run_pipeline_interactive.R`
**Interactive Execution Alternative**
- Provides a simple, RStudio-friendly way to run the entire pipeline
- Automatically checks for and installs all required R packages if missing
- Sources both module scripts (`data-loading.R` and `data-models.R`)
- Executes the complete end-to-end pipeline (equivalent to `Rscript main.R --all`)
- Useful when:
  - R binary is not in PATH
  - Command-line execution requires administrative rights
  - Users prefer working within RStudio IDE
  - Testing or debugging the pipeline interactively

## Data Sources

All data is retrieved from the **IDB DATA API** (Inter-American Development Bank):

### Formality Indicators (SILAC)
- **formal_1**: % of economically active workers contributing to social security
- **formal_2**: % of employed workers contributing to social security

### Socioeconomic Variables (SILAC)
- **avg_educ_years**: Average years of schooling (economically active population)
- **employed_agriculture**: % of employed workers in agriculture
- **min_wage**: Minimum legal monthly wage, PPP (constant 2011 international $)
- **gov_exp_educ**: Government expenditure on education (% of GDP)
- **rural_pop**: % of population in rural areas

### Macroeconomic Variables (LMW)
- **gdp_per_capita**: GDP per capita (US$, current prices)
- **cpi**: Consumer Price Index (period average)
- **credit**: Total Credit (real index, period average)
- **fdi**: Foreign Direct Investment, Net (% of GDP)

### Countries Included
Argentina (ARG), Bolivia (BOL), Brazil (BRA), Colombia (COL), Costa Rica (CRI), Dominican Republic (DOM), Ecuador (ECU), Guatemala (GTM), Honduras (HND), Mexico (MEX), Panama (PAN), Paraguay (PRY), Peru (PER), El Salvador (SLV), Uruguay (URY)

## Expected Outputs

After running the pipeline, the following files will be generated:

### Data Files (`data/`)
- `api-raw/*.csv`: Raw data files for each variable
- `master_data.csv`: Merged dataset before imputation
- `master_data_filled.csv`: Final dataset with missing values handled

### Analysis Outputs (`outputs/`)
- `summary_table_prehandling.html`: Descriptive statistics before imputation
- `summary_table.html`: Descriptive statistics of final dataset
- `pairsplot_features.png`: Correlation matrix and scatter plots
- `main_results.html`: Regression results table

## Troubleshooting

### "R command not found" Error
- Ensure R is properly installed
- Add R to your system PATH (especially on Windows)
- Alternatively, use the interactive method via RStudio

### Package Installation Issues
- The project uses `renv` for dependency management
- On first run, `renv::restore()` will install all required packages
- If issues persist, try running `renv::restore(prompt = FALSE)` in an R console

### Permission/sudo Issues
- Use the interactive execution method (`run_pipeline_interactive.R` in RStudio)
- This bypasses command-line permission requirements

## Contact

For questions, suggestions, or issues, please contact:

**Carlos A. Toruño Paniagua**  
Email: carlos.toruno@gmail.com