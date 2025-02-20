# Main file to process and generate replications from original collected forms from IE and UVA universities (Segovia 2024-2025)

library(magrittr) # pipes
library(data.table) # data wrangling
library(survey) # survey data
library(readxl) # read excel files
library(mice) # library for dealing with multiple imputations
library(missRanger)

# Prepare environment by cleaning any previous object in memory
gc()
rm(list = ls())

# Read original forms
ie_forms <- read_excel("Encuestas/IE.2025.xlsx") %>% data.table()
uv_forms <- read_excel("Encuestas/UVA.2025.xlsx") %>% data.table()

# Convert 'hora_de_inicio' to POSIXct format to avoid errors
ie_forms[, `hora_de_inicio` := as.POSIXct(`hora_de_inicio`, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")]
uv_forms[, `hora_de_inicio` := as.POSIXct(`hora_de_inicio`, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")]

# Ensure consistent column types
ie_forms[] <- lapply(ie_forms, function(x) if (is.character(x)) as.factor(x) else x)
uv_forms[] <- lapply(uv_forms, function(x) if (is.character(x)) as.factor(x) else x)

# Exclude non-imputable variables
exclude_vars <- c("hora_de_inicio", "hora_de_finalizacion", "id")
ie_clean <- ie_forms[, !exclude_vars, with = FALSE]
uv_clean <- uv_forms[, !exclude_vars, with = FALSE]

# Main file to process and generate replications from original collected forms from IE and UVA universities (Segovia 2024-2025)

