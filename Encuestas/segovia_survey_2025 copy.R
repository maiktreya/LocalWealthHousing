# Main file to process and generate replications from original collected forms from IE and UVA universities (Segovia 2024-2025)

library(magrittr) # pipes
library(data.table) # data wrangling
library(survey) # survey data
library(readxl) # read excel files
library(mi) # library for dealing with multiple imputations

# Prepare environment by cleaning any previous object in memory
gc()
rm(list = ls())

# Read original forms
ie_forms <- read_excel("Encuestas/IE.2025.xlsx") %>% data.table()
uv_forms <- read_excel("Encuestas/UVA.2025.xlsx") %>% data.table()

# Convert 'Start time' to POSIXct format to avoid errors
ie_forms[, `Start time` := as.POSIXct(`Start time`, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")]
uv_forms[, `Start time` := as.POSIXct(`Start time`, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")]

# Ensure consistent column types
ie_forms[] <- lapply(ie_forms, function(x) if (is.character(x)) as.factor(x) else x)
uv_forms[] <- lapply(uv_forms, function(x) if (is.character(x)) as.factor(x) else x)

# Exclude non-imputable variables
exclude_vars <- c("Start time", "End time", "ID")
ie_clean <- ie_forms[, !exclude_vars, with = FALSE]
uv_clean <- uv_forms[, !exclude_vars, with = FALSE]

# Function to perform multiple imputation
generate_imputations <- function(data, m = 5) {
    # Convert data.table to data frame for mi package compatibility
    data <- as.data.frame(data)

    # Define missing data object
    missing_data <- missing_data.frame(data)

    # Perform multiple imputations
    imputed_data <- mi(missing_data, n.iter = 30, n.chains = m) # 30 iterations, 5 imputations

    # Convert imputations to a list of completed datasets
    completed_datasets <- complete(imputed_data, m)

    return(completed_datasets)
}

# Generate 5 multiple imputations for each form
ie_imputations <- generate_imputations(ie_clean, m = 5)
uv_imputations <- generate_imputations(uv_clean, m = 5)

# Convert imputed datasets back to data.table format
ie_imputations <- lapply(ie_imputations, data.table)
uv_imputations <- lapply(uv_imputations, data.table)

# Save imputed datasets for further analysis
saveRDS(ie_imputations, "Imputed_Data/IE_Imputations.RDS")
saveRDS(uv_imputations, "Imputed_Data/UVA_Imputations.RDS")


