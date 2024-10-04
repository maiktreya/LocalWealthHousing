# Obtain t-statisctics for representative mean for AEAT subsample

# clean enviroment and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")

# define city subsample and variables to analyze
city <- "segovia"
represet <- "!is.na(FACTORCAL)" # población
sel_year <- 2021
ref_unit <- "IDENHOG"
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
    raked = FALSE # Working just for Madrid & Segovia cities
)
subsample <- svydesign(
    ids = ~1,
    data = subset(dt, MUESTRA == city_index),
    weights = dt$FACTORCAL,
    # calibrate.formula = ~1
) # muestra con coeficientes de elevación

# calculate sample means
RNmean <- svymean(~RENTAD, subsample)
RBmean <- svymean(~RENTAB, subsample)

# Test if the survey means are equal to the population means
test_rep1 <- svycontrast(RNmean, quote(RENTAD - RNpop))
test_rep2 <- svycontrast(RBmean, quote(RENTAB - RBpop))
net_vals <- data.table(
    pop = RNpop,
    mean = coef(RNmean),
    stat = as.numeric(test_rep1),
    b95l = as.numeric(test_rep1) + SE(RNmean) * -1.96,
    b95u = as.numeric(test_rep1) + SE(RNmean) * 1.96,
    se = SE(RNmean),
    dif = (RNpop - coef(RNmean)) / RNpop
)
gross_vals <- data.table(
    pop = RBpop,
    mean = coef(RBmean),
    stat = as.numeric(test_rep2),
    b95l = as.numeric(test_rep2) + SE(RBmean) * -1.96,
    b95u = as.numeric(test_rep2) + SE(RBmean) * 1.96,
    se = SE(RBmean),
    dif = (RBpop - coef(RBmean)) / RBpop
)
results <- rbind(net_vals, gross_vals, use.names = FALSE) %>%
    round(2) %>%
    print()
sum(1 / subsample$variables[, "FACTORCAL"]) %>% print()
sum(subsample$variables[, "FACTORCAL"]) %>% print()
