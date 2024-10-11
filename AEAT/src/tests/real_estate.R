# clean enviroment and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
city <- "madrid"
sel_year <- 2021
ref_unit <- "IDENHOG"
pop_stats <- fread("AEAT/data/pop-stats.csv")
RNpop <- pop_stats[muni == city & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]
RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]
dt <- fread(paste0("AEAT/data/madridIDENHOG", sel_year, ".gz"))

# import external population values
city_index <- fread("AEAT/data/pop-stats.csv")[muni == city & year == sel_year, index]
tipohog_pop <- fread(paste0("AEAT/data/tipohog-", city, "-", sel_year, ".csv"), encoding = "UTF-8")[, .(Tipohog = as.factor(Tipohog), Total)]
tramo_pop <- fread(paste0("AEAT/data/base_hogar/", city, sel_year, "_tramo.csv"), encoding = "UTF-8")[, .(Tramo = as.factor(Tramo), Total)]
tipohog_pop <- setNames(tipohog_pop$Total, paste0("TIPOHOG", tipohog_pop$Tipohog))
tramo_pop <- setNames(tramo_pop$Total, paste0("TRAMO", tramo_pop$Tramo))

# coerce needed variables
dt <- dt[!is.na(FACTORCAL)]
dt[, TIPOHOG := as.factor(TIPOHOG)]
dt[, TRAMO := as.factor(TRAMO)]

# Prepare survey object
dt_sv <- svydesign(
    ids = ~IDENHOG,
    strata = ~ CCAA + TIPOHOG + TRAMO,
    data = dt,
    weights = dt$FACTORCAL,
    nest = TRUE
)
pre_subsample <- subset(dt_sv, MUESTRA == city_index)
limits <- c(min(weights(pre_subsample)), max(weights(pre_subsample)))
calibration_totals_vec <- c(tipohog_pop, RENTAB = RBpop * sum(weights(pre_subsample)), RENTAD = RNpop * sum(weights(pre_subsample)))

# Apply calibration with the new named vector
subsample <- calibrate(
    design = pre_subsample,
    formula = ~ -1 + TIPOHOG + RENTAB + RENTAD,
    population = calibration_totals_vec,
    calfun = "raking",
    bounds = limits,
    bounds.const = TRUE
)

dt <- subsample$variables
dt[, FACTORCAL := weights(subsample)]

### -------------------------------------------------------


dt <- subset(dt, MUESTRA == city_index)

# define survey for the subsample of interest
subsample <- svydesign(ids = ~IDENHOG, data = dt, weights = dt$FACTORCAL)
# calculate sample means
RNmean <- svymean(~RENTAD, subsample)
RBmean <- svymean(~RENTAB, subsample)

# Test if the survey means are equal to the population means
test_rep1 <- svycontrast(RNmean, quote(RENTAD - RNpop)) %>% as.numeric()
test_rep2 <- svycontrast(RBmean, quote(RENTAB - RBpop)) %>% as.numeric()

# Calculate p-values using two-tailed test over t-statistics
p_val1 <- 2 * (1 - pnorm(abs(test_rep1 / SE(RNmean))))
p_val2 <- 2 * (1 - pnorm(abs(test_rep2 / SE(RBmean))))

# Prepare the results table with p-values for gross and net income
net_vals <- data.table(
    pop = RNpop,
    mean = coef(RNmean),
    stat = test_rep1,
    se = SE(RNmean),
    dif = (RNpop - coef(RNmean)) / RNpop,
    p_value = p_val1
) %>% round(3)
gross_vals <- data.table(
    pop = RBpop,
    mean = coef(RBmean),
    stat = test_rep2,
    se = SE(RBmean),
    dif = (RBpop - coef(RBmean)) / RBpop,
    p_value = p_val2
) %>% round(3)

# Combine and print the results

results <- rbind(net_vals, gross_vals, use.names = FALSE)
colnames(results) <- c("pop", "mean", "stat", "se", "dif%", "p_value")
results %>% print()

# Print sample sizes and weight summary
print("Sample size original:")
sum(pre_subsample$variables[, "FACTORCAL"]) %>% print()
print("Sample size Reweighted:")
sum(subsample$variables[, "FACTORCAL"]) %>% print()
print("Summary of calibrated weights")
summary(weights(subsample)) %>% print()
