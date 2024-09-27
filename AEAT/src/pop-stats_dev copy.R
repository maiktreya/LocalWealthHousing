# Obtain population statistics for AEAT subsample

# Clean environment to avoid RAM bottlenecks and import dependencies

rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
library(dineq)
source("AEAT/src/transform/etl_pipe.R")

# Import needed data objects
sel_year <- 2016
age <- fread("AEAT/data/madrid-age.csv")
sex <- fread("AEAT/data/madrid-sex.csv")
dt <- fread("AEAT/data/IEF-2016-new.gz")
age_labels <- c(
    "De 0 a 4 años", "De 5 a 9 años", "De 10 a 14 años",
    "De 15 a 19 años", "De 20 a 24 años", "De 25 a 29 años",
    "De 30 a 34 años", "De 35 a 39 años", "De 40 a 44 años",
    "De 45 a 49 años", "De 50 a 54 años", "De 55 a 59 años",
    "De 60 a 64 años", "De 65 a 69 años", "De 70 a 74 años",
    "De 75 a 79 años", "De 80 a 84 años", "De 85 a 89 años",
    "De 90 a 94 años", "De 95 a 99 años", "100 y más años"
)


########################################################
# Example age vector (replace this with your actual data)
dt[, gender := "female"][SEXO == 1, gender := "male"]
dt[, AGE := sel_year - ANONAC]

# Apply the cut() function with age breaks and labels
dt[, age_group := cut(
    AGE,
    breaks = seq(0, 105, by = 5), # Adjusting the upper limit to 105 to cover "100 y más años"
    right = FALSE,
    labels = age_labels,
    include.lowest = TRUE # Ensures the lowest interval includes the lower bound
)]
dt <- dt[!is.na(age_group)]
sex_vector <- sex[, total := NULL][year == sel_year][, year := NULL]
sex_vector <- sex_vector / sum(sex_vector)
sex_vector <- sex_vector[order(names(sex_vector))]

# age categories
age_vector <- age[, get(paste0("total", sel_year))]
age_vector <- age_vector / sum(age_vector)
names(age_vector) <- age_labels
age_vector <- age_vector[order(names(age_vector))]

dt[, age_group := factor(age_group, levels = names(age_vector))]


# Define raking margins
margins <- list(
    ~gender, # Rake by sex
    ~age_group # Rake by age group
)

# Population proportions for raking
pop_totals <- list(
    sex_vector, # Use the male/female proportions
    age_vector # Use the age group proportions
)

# Prepare survey object from dt and set income cuts for quantiles dynamically
dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL) # muestra con coeficientes de elevación
subsample <- subset(dt_sv, CCAA == "13" & PROV == "28" & MUNI == "79")

# Apply raking
raked_design <- rake(
    design = subsample,
    sample.margins = margins,
    population.margins = pop_totals
)
