# Obtain population statistics for AEAT subsample

# Clean environment to avoid RAM bottlenecks and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")

# Import needed data objects
sel_year <- 2021
age <- fread("AEAT/data/madrid-age.csv")
sex <- fread("AEAT/data/madrid-sex.csv")
dt <- fread("AEAT/data/IEF-2021-new.gz")
# Example age vector (replace this with your actual data)
dt[, gender := "female"][SEXO == 1, gender := "male"]
dt[, AGE := sel_year - ANONAC]

dt[, age_group := cut(
    AGE,
    breaks = seq(0, 105, by = 5), # Adjusting the upper limit to 105 to cover "100 y más años"
    right = FALSE,
    labels = c(1:21),
    include.lowest = TRUE # Ensures the lowest interval includes the lower bound
)]
dt <- dt[!is.na(age_group)]

# age categories
age_vector <- age[, get(paste0("total", sel_year))]
age_vector <- age_vector / sum(age_vector)
age_vector <- data.frame(age_group = c(1:21), Freq = as.numeric(age_vector))  # Convert to data.frame)


# Clean and normalize sex vector
sex_vector <- sex[, total := NULL][year == sel_year][, year := NULL]
sex_vector <- sex_vector / sum(sex_vector)
sex_vector <- data.frame(gender = c("male", "female"), Freq = as.numeric(sex_vector))  # Convert to data.frame

# Define raking margins
margins <- list(
    ~gender,  # Rake by gender
    ~age_group  # Rake by sex
)

# Population proportions for raking
pop_totals <- list(
    sex_vector
    , age_vector  # Use the male/female proportions as a data.frame
)

# Prepare survey object from dt and set income cuts for quantiles dynamically
dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL) # muestra con coeficientes de elevación
subsample <- subset(dt_sv, CCAA.x == "13" & PROV.x == "28" & MUNI.x == "79")

# Apply raking
raked_design <- rake(
    design = subsample,
    sample.margins = margins,
    population.margins = pop_totals
)

