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
    calibrated = FALSE,
    raked = TRUE # Working just for Madrid & Segovia cities
)
dt2 <- fread(paste0("AEAT/data/IEF-", sel_year, "-new.gz"))
original_design <- svydesign(ids = ~1, data = subset(dt2, CCAA == "13" & PROV == "28" & MUNI == "79"), weights = dt2$FACTORCAL)
calibrated_design <- svydesign(ids = ~1, data = subset(dt, MUESTRA == city_index), weights = dt$FACTORCAL)


#################################

# Summary statistics for weights
ori_weights <- summary(weights(original_design)) %>% print()
cal_weights <- summary(weights(calibrated_design)) %>% print()

min_weight <- min(ori_weights)
max_weight <- max(ori_weights)
trimmed_weights <- pmax(pmin(weights(calibrated_design), max_weight), min_weight)

add <- TRUE
if (add) {
    subsample <- calibrated_design
    weights(subsample) <- trimmed_weights
    # calculate sample means
    RNmean <- svymean(~RENTAD, subsample)
    RBmean <- svymean(~RENTAB, subsample)

    # Test if the survey means are equal to the population means
    test_rep1 <- svycontrast(RNmean, quote(RENTAD - RNpop)) %>% print()
    test_rep2 <- svycontrast(RBmean, quote(RENTAB - RBpop)) %>% print()
}
