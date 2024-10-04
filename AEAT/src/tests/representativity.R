# clean enviroment and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")

# define city subsample and variables to analyze
city <- "madrid" # city to subsample
represet <- "!is.na(FACTORCAL)" # reference population
sel_year <- 2021 # wave
ref_unit <- "IDENHOG" # PSU
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
    calibrated =  TRUE, # Requieres auxiliary pop. data
    raked = "INTERACTION" # Requieres auxiliary pop. data
)
subsample <- svydesign(
    ids = ~1,
    data = subset(dt, MUESTRA == city_index),
    weights = dt$FACTORCAL
)

# calculate sample means
RNmean <- svymean(~RENTAD, subsample)
RBmean <- svymean(~RENTAB, subsample)

# Test if the survey means are equal to the population means
test_rep1 <- svycontrast(RNmean, quote(RENTAD - RNpop)) %>% as.numeric()
test_rep2 <- svycontrast(RBmean, quote(RENTAB - RBpop)) %>% as.numeric()

# Calculate t-statistics
t_stat1 <- test_rep1 / SE(RNmean)
t_stat2 <- test_rep2 / SE(RBmean)

# Calculate p-values using two-tailed test
p_val1 <- 2 * (1 - pnorm(abs(t_stat1)))
p_val2 <- 2 * (1 - pnorm(abs(t_stat2)))

# Prepare the results table with p-values
net_vals <- data.table(
    pop = RNpop,
    mean = coef(RNmean),
    stat = test_rep1,
    se = SE(RNmean),
    dif = (RNpop - coef(RNmean)) / RNpop,
    p_value = p_val1
)
gross_vals <- data.table(
    pop = RBpop,
    mean = coef(RBmean),
    stat = test_rep2,
    se = SE(RBmean),
    dif = (RBpop - coef(RBmean)) / RBpop,
    p_value = p_val2
)

# Combine and print the results
results <- rbind(net_vals, gross_vals, use.names = FALSE) %>%
    round(3) %>%
    print()

# Print sample sizes
sum(1 / subsample$variables[, "FACTORCAL"]) %>% print()
sum(subsample$variables[, "FACTORCAL"]) %>% print()
