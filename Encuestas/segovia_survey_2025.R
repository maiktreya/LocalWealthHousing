# Main file to process and generate replications from original collected forms from IE and UVA universities (Segovia 2024-2025)

library(magrittr) # pipes
library(data.table) # data wrangling
library(survey) # survey data
library(readxl) # read excel files
library(mice) # library for dealing with multiple imputations
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


# Average imputations for IE
final_IE <- filledIE[[1]] # Start with first imputation as template
for (col in names(final_IE)) {
    if (is.numeric(final_IE[[col]])) {
        # For numeric columns, calculate mean across all imputations
        final_IE[[col]] <- rowMeans(sapply(filledIE, function(x) x[[col]]))
    } else {
        # For categorical columns, take mode (most frequent value)
        final_IE[[col]] <- apply(
            sapply(filledIE, function(x) x[[col]]), 1,
            function(x) names(sort(table(x), decreasing = TRUE)[1])
        )
    }
}

# Average imputations for UV
final_UV <- filledUV[[1]] # Start with first imputation as template
for (col in names(final_UV)) {
    if (is.numeric(final_UV[[col]])) {
        # For numeric columns, calculate mean across all imputations
        final_UV[[col]] <- rowMeans(sapply(filledUV, function(x) x[[col]]))
    } else {
        # For categorical columns, take mode (most frequent value)
        final_UV[[col]] <- apply(
            sapply(filledUV, function(x) x[[col]]), 1,
            function(x) names(sort(table(x), decreasing = TRUE)[1])
        )
    }
}

# Convert to data.table format
final_IE <- as.data.table(final_IE)
final_UV <- as.data.table(final_UV)

# Save final datasets
write.xlsx(final_IE, "Encuestas/IE_final_imputed.xlsx")
write.xlsx(final_UV, "Encuestas/UV_final_imputed.xlsx")
