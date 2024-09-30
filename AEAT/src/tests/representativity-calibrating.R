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
ref_unit <- "IDENHOG"
age_labels <- c("A", "B", "C", "D", "E", "F")
dt <- get_wave(sel_year = sel_year, ref_unit = ref_unit, represet = represet)

# population values
pop_stats <- fread("AEAT/data/pop-stats.csv")
RNpop <- pop_stats[muni == city & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]
RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]

# Prepare survey object from dt and set income cuts for quantiles dynamically
dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL) # muestra con coeficientes de elevación
pre_subsample <- subset(dt_sv, CIUDAD == city)

# Define the population mean you want to match
true_mean_income <- RBpop # Replace with the true population mean for your subsample
pop_size <- pre_subsample$variables[, FACTORCAL] %>% sum() # 3280782
calibration_target <- c(RENTAB = true_mean_income * pop_size)

# Run the calibration again
subsample <- calibrate(pre_subsample, ~ -1 + RENTAB, calibration_target)

# Test sample means against true population means using svycontrast
RNmean <- svymean(~RENTAD, subsample)
RBmean <- svymean(~RENTAB, subsample)

# Test if the survey means are equal to the population means
test_rep1 <- svycontrast(RNmean, quote(RENTAD - RNpop)) %>% print()
test_rep2 <- svycontrast(RBmean, quote(RENTAB - RBpop)) %>% print()

# Summarize the results
net_vals <- data.table(
    pop = RNpop,
    mean = coef(RNmean),
    se = SE(RNmean),
    dif = (RNpop - coef(RNmean)) / RNpop
)

gross_vals <- data.table(
    pop = RBpop,
    mean = coef(RBmean),
    se = SE(RBmean),
    dif = (RBpop - coef(RBmean)) / RBpop
)
results <- rbind(net_vals, gross_vals, use.names = FALSE) %>% print()
