# clean enviroment and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")
pop_stats <- fread("AEAT/data/pop-stats.csv")

# define city subsample and variables to analyze
export_object <- FALSE
city <- "madrid"
represet <- "!is.na(FACTORCAL)"
sel_year <- 2016
ref_unit <- "IDENHOG"
rake_mode <- "INTERACTION"
calib_mode <- TRUE
city_index <- pop_stats[muni == city & year == sel_year, index]
RNpop <- pop_stats[muni == city & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]
RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]

# get a sample weighted for a given city
dt <- get_wave(
    city = city, # subregional unit
    sel_year = sel_year, # wave
    ref_unit = ref_unit, # reference PSU (either household or individual)
    represet = represet, # reference universe/population (whole pop. or tax payers)
    calibrated = calib_mode, # Weight calib. (TRUE, FALSE, TWO-STEPS) Requieres auxiliary total/mean data
    raked = rake_mode # Iterative resampling (TRUE, FALSE, INTERACTION) Requieres auxiliary freq. data
)
dt <- subset(dt, MUESTRA == city_index)

# define survey for the subsample of interest
subsample <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL)

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
results <- rbind(net_vals, gross_vals, use.names = FALSE) %>% print()

# Print sample sizes
sum(1 / subsample$variables[, "FACTORCAL"]) %>% print()
sum(subsample$variables[, "FACTORCAL"]) %>% print()
summary(weights(subsample)) %>% print()

# Export the final reweighted subsample if needed
if (export_object) fwrite(subsample$variables, paste0("AEAT/out/", city, ref_unit, sel_year, rake_mode, ".gz"))



##########################

    age_labels <- c("0-24", "25-49", "50-74", "+75")

    pop_stats <- fread("AEAT/data/pop-stats.csv")
    city_index <- pop_stats[muni == city & year == sel_year, index] %>% as.numeric()
    total_pop <- fread(paste0("AEAT/data/base/", city, "-sex.csv"))[year == sel_year, total]

    # reshape sex categories
    sex_vector <- fread(paste0("AEAT/data/", city, "-sex-freq.csv"))[, .(gender, Freq = get(paste0("freq", sel_year)))]

    # reshape age categories
    age_vector <- fread(paste0("AEAT/data/", city, "-age-freq.csv"))[, .(age_group, Freq = get(paste0("freq", sel_year)))]
    age_vector <- age_vector[, group := ceiling(.I / 5)][, .(Freq = sum(Freq)), by = group][, Freq := Freq * total_pop]
    age_vector <- cbind(age_group = age_labels, age_vector)[, group := NULL]

    # Create a new age_group based on broader 20-year intervals