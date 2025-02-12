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

# https://cran.r-project.org/web/packages/missRanger/vignettes/multiple_imputation.html

ie_forms_NA1 <- generateNA(ie_forms, p = c(0, 0.1, 0.1, 0.1, 0.1))
ie_forms_NA2 <- generateNA(ie_forms, p = c(0, 0.1, 0.1, 0.1, 0.1))

# Generate 20 complete data sets with relatively large pmm.k
filled1 <- replicate(
    20,
    missRanger(ie_forms_NA1, verbose = 0, num.trees = 100, pmm.k = 10),
    simplify = FALSE
)
filled2 <- replicate(
    20,
    missRanger(ie_forms_NA2, verbose = 0, num.trees = 100, pmm.k = 10),
    simplify = FALSE
)

# test differences in generations
difs <- data.table()
for (i in 1:20) {
    aa <- filled1[[i]]$Age %>% as.numeric()
    bb <- filled2[[i]]$Age %>% as.numeric()
    dif <- aa - bb
    difs <- cbind(difs, dif)
}
print(difs)
