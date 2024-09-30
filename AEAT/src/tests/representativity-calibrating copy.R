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
sel_year <- 2021
ref_unit <- "IDENPER"
age_labels <- c("0-19", "20-39", "40-59", "60-79", "80-99", "100+")
dt <- get_wave(sel_year = sel_year, ref_unit = ref_unit, represet = represet)

# population values
pop_stats <- fread("AEAT/data/pop-stats.csv")
RNpop <- pop_stats[muni == city & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]
RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]

# reshape sex categories
sex_vector <- fread("AEAT/data/madrid-sex-freq.csv")[, .(gender, Freq = get(paste0("freq", sel_year)))]

# reshape age categories
age_vector <- fread("AEAT/data/madrid-age-freq.csv")[, .(age_group, Freq = get(paste0("freq", sel_year)))]
age_vector <- age_vector[, group := ceiling(.I / 4)][, .(Freq = sum(Freq)), by = group]
age_vector <- cbind(age_group =age_labels, age_vector)[, group := NULL]

# Create a new age_group based on broader 20-year intervals, with the last one open-ended
dt[, age_group := cut(
    AGE,
    breaks = c(0, 20, 40, 60, 80, 100, Inf), # Defining 20-year groups with the last being open-ended
    right = FALSE,
    labels = age_labels,
    include.lowest = TRUE
)]
dt <- dt[!is.na(age_group)]
dt[, gender := "female"][SEXO == 1, gender := "male"]

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
pre_subsample <- subset(dt_sv, CIUDAD == city)

# Define the population mean you want to match
true_mean_income <- 22587 # Replace with the true population mean for your subsample
pop_size <- 3280782
calibration_target <- data.frame(
`(Intercept)` = 3280782, 
"X.0.19" = 564105,
"X20.39" = 843254,
"X40.59" = 1003744,
"X60.79" = 636385,
"X80.900" = 231678,
"X100." = 1616)

subsample <- calibrate(pre_subsample, ~  age_group, calibration_target)

