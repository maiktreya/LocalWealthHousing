# Obtain t-statisctics for representative mean for AEAT subsample

# clean enviroment and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")

# define city subsample and variables to analyze
city <- "madrid"
represet <- "!is.na(FACTORCAL)" # población
sel_year <- 2016
ref_unit <- "IDENPER"
pop_stats <- fread("AEAT/data/pop-stats.csv")
city_index <- pop_stats[muni == city & year == sel_year, index]
RNpop <- pop_stats[muni == city & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]
RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]

# get subsample
dt <- get_wave(
    city = city,
    sel_year = sel_year,
    ref_unit = ref_unit,
    represet = represet,
    calibrated = TRUE,
    raked = TRUE # Working just for Madrid & Segovia cities
)
dt2 <- fread("AEAT/doc/IEF-2016-nocal.gz")
original_design <- svydesign(ids = ~1, data = subset(dt2, MUESTRA == city_index), weights = dt2$FACTORCAL)
calibrated_design <- svydesign(ids = ~1, data = subset(dt, MUESTRA == city_index), weights = dt$FACTORCAL)

#################################

# Summary statistics for weights
ori_weights <- summary(weights(original_design)) %>% print()
cal_weights <- summary(weights(calibrated_design)) %>% print()

# Plot distribution of weights
hist(weights(calibrated_design), main = "Distribution of Weights", xlab = "Weights")
hist(weights(original_design), main = "Distribution of Weights", xlab = "Weights")


cal_weights_trimmed <- pmax(cal_weights, 0)  # Replace negative weights with 0
min_weight <- min(ori_weights)
max_weight <- max(ori_weights)

trimmed_weights <- pmax(pmin(cal_weights, max_weight), min_weight)


#############################

# Calculate percentiles
quantile(weights(calibrated_design), probs = c(0.01, 0.99))

# Set max and min weight based on percentiles
min_weight <- quantile(weights(calibrated_design), probs = 0.01)
max_weight <- quantile(weights(calibrated_design), probs = 0.99)
