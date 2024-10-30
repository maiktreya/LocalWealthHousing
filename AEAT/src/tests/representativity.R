# clean enviroment and import dependencies
rm(list = ls())
gc(full = TRUE, verbose = TRUE)
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")
pop_stats <- fread("AEAT/data/pop-stats.csv")

# define city subsample and variables to analyze
city <- "segovia"
represet <- "!is.na(FACTORCAL)"
sel_year <- 2021
ref_unit <- "IDENHOG"
calib_mode <- TRUE
RNpop <- pop_stats[muni == city & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]
RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]

# get a sample weighted for a given city
dt <- get_wave(
    city = city, # subregional unit
    sel_year = sel_year, # wave
    ref_unit = ref_unit, # reference PSU (either household or individual)
    represet = represet, # reference universe/population (whole pop. or tax payers)
    calibrated = calib_mode, # Weight calib. (TRUE, FALSE, TWO-STEPS) Requieres auxiliary total/mean data
) %>% subset(MUESTRA == pop_stats[muni == city & year == sel_year, index])

# define survey for the subsample of interest
subsample <- svydesign(
    ids = ~IDENHOG,
    data = dt,
    weights = dt$FACTORCAL
)

# calculate sample means
RNmean <- svymean(~RENTAD, subsample)
RBmean <- svymean(~RENTAB, subsample)

# Test if the survey means are equal to the population means
test_rep1 <- svycontrast(RNmean, quote(RENTAD - RNpop)) %>% as.numeric()
test_rep2 <- svycontrast(RBmean, quote(RENTAB - RBpop)) %>% as.numeric()

# Calculate p-values using two-tailed test over t-statistics
p_val1 <- 2 * (1 - pnorm(abs(test_rep1 / SE(RNmean))))
p_val2 <- 2 * (1 - pnorm(abs(test_rep2 / SE(RBmean))))

# Calculate Margins of Error
moe_rentab <- 1.96 * data.frame(RBmean)$RENTAB
moe_rentad <- 1.96 * data.frame(RNmean)$RENTAD

# Prepare the results table with p-values for gross and net income
net_vals <- data.table(
    pop = RNpop,
    mean = coef(RNmean),
    stat = test_rep1,
    se = SE(RNmean),
    RSE = (SE(RNmean) / coef(RNmean)),
    dif = (RNpop - coef(RNmean)) / RNpop,
    p_value = p_val1,
    MOE = (moe_rentad / coef(RNmean))
) %>% round(3)
gross_vals <- data.table(
    pop = RBpop,
    mean = coef(RBmean),
    stat = test_rep2,
    se = SE(RBmean),
    RSE = (SE(RNmean) / coef(RNmean)),
    dif = (RBpop - coef(RBmean)) / RBpop,
    p_value = p_val2,
    MOE = (moe_rentab / coef(RBmean))
) %>% round(3)
colnames(net_vals) <- colnames(gross_vals) <- c("pop", "mean", "stat", "se", "RSE", "dif", "pval", "MOE")

# Combine and print the results
results <- rbind(net_vals, gross_vals, use.names = FALSE) %>% print()

# Print implied population size and weights summary
print("Implied Pop. size Reweighted:")
sum(subsample$variables[, "FACTORCAL"]) %>% print()
print("Summary of calibrated weights")
summary(weights(subsample)) %>% print()
