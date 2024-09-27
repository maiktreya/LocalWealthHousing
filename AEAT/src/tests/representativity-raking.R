# Obtain population statistics for AEAT subsample

# Clean environment to avoid RAM bottlenecks and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")

# Import needed data objects
city <- "madrid"
represet <- "!is.na(FACTORCAL)" # población
sel_year <- 2016
ref_unit <- "IDENPER"
age <- fread("AEAT/data/madrid-age.csv")
sex <- fread("AEAT/data/madrid-sex.csv")
dt <- get_wave(sel_year = sel_year, ref_unit = ref_unit, represet = represet)
# Example age vector (replace this with your actual data)
dt[, gender := "female"][SEXO == 1, gender := "male"]

# Create a new age_group based on broader 20-year intervals, with the last one open-ended
dt[, age_group := cut(
    AGE,
    breaks = c(0, 20, 40, 60, 80, 100, Inf), # Defining 20-year groups with the last being open-ended
    right = FALSE,
    labels = c("0-19", "20-39", "40-59", "60-79", "80-99", "100+"),
    include.lowest = TRUE
)]


dt <- dt[!is.na(age_group)]

# age categories
age_vector <- age[, get(paste0("total", sel_year))]
age_vector <- age_vector / sum(age_vector)
age_vector <- data.frame(age_group = c(1:21), Freq = as.numeric(age_vector)) # Convert to data.frame)
age_vector <- data.table(age_vector)[, group := ceiling(.I / 4)][, .(Freq = sum(Freq)), by = group]
age_vector <- cbind(age_group = c("0-19", "20-39", "40-59", "60-79", "80-99", "100+"), age_vector)[, group := NULL]
# Clean and normalize sex vector
sex_vector <- sex[, total := NULL][year == sel_year][, year := NULL]
sex_vector <- sex_vector / sum(sex_vector)
sex_vector <- data.frame(gender = c("male", "female"), Freq = as.numeric(sex_vector)) # Convert to data.frame

# Define raking margins
margins <- list(
    ~gender, # Rake by gender
    ~age_group # Rake by sex
)

# Population proportions for raking
pop_totals <- list(
    sex_vector,
    age_vector # Use the male/female proportions as a data.frame
)

# Prepare survey object from dt and set income cuts for quantiles dynamically
dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL) # muestra con coeficientes de elevación
subsample <- subset(dt_sv, CIUDAD == "madrid")

# Apply raking
raked_design <- rake(
    design = subsample,
    sample.margins = margins,
    population.margins = pop_totals
)
