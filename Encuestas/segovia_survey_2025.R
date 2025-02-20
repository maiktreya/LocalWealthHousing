# Main file to process and generate replications from original collected forms from IE and UVA universities (Segovia 2024-2025)

library(magrittr) # pipes
library(data.table) # data wrangling
library(survey) # survey data
library(readxl) # read excel files
library(missRanger) # to impute values
library(openxlsx) # for writing Excel files

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

ie_clean[ie_clean == ""] <- NA
uv_clean[uv_clean == ""] <- NA

# https://cran.r-project.org/web/packages/missRanger/vignettes/multiple_imputation.html

# Generate 20 complete data sets with relatively large pmm.k
filledIE <- replicate(
    20,
    missRanger(ie_clean, verbose = 0, num.trees = 100, pmm.k = 10),
    simplify = FALSE
)
filledUV <- replicate(
    20,
    missRanger(uv_clean, verbose = 0, num.trees = 100, pmm.k = 10),
    simplify = FALSE
)

# Merge imputed datasets for IE
merged_IE <- filledIE[[1]] # Start with first imputation
for (i in 2:20) {
    # Add suffix to column names to identify imputation number
    temp_df <- filledIE[[i]]
    names(temp_df) <- paste0(names(temp_df), "_imp", i)
    merged_IE <- cbind(merged_IE, temp_df)
}

# Merge imputed datasets for UV
merged_UV <- filledUV[[1]] # Start with first imputation
for (i in 2:20) {
    # Add suffix to column names to identify imputation number
    temp_df <- filledUV[[i]]
    names(temp_df) <- paste0(names(temp_df), "_imp", i)
    merged_UV <- cbind(merged_UV, temp_df)
}

# Convert to data.table format
merged_IE <- as.data.table(merged_IE)
merged_UV <- as.data.table(merged_UV)

# Save merged datasets if needed
write.xlsx(merged_IE, "Encuestas/IE_merged_imputations.xlsx")
write.xlsx(merged_UV, "Encuestas/UV_merged_imputations.xlsx")
