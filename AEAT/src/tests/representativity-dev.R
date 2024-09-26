# Obtain t-statisctics for representative mean for AEAT subsample

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
RNpop <- pop_stats[muni == city & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]
RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]
dt <- get_wave(sel_year = sel_year, ref_unit = ref_unit, represet = represet)

## Prepare survey object from dt and set income cuts for quantiles dynamically
dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL) # muestra con coeficientes de elevación
subsample <- subset(dt_sv, CIUDAD == city) # subset for a given city

# Test sample means against true population means using svycontrast
RNmean <- svymean(~RENTAD, subsample)
RBmean <- svymean(~RENTAB, subsample)

# Test if the survey means are equal to the population means
test_rep1 <- svycontrast(RNmean, quote(RENTAD - RNpop)) %>% print()
test_rep2 <- svycontrast(RBmean, quote(RENTAB - RBpop)) %>% print()

# Summarize the results
net_vals <- data.table(pop = RNpop,
 mean = coef(RNmean),
se = SE(RNmean),
dif = (RNpop - coef(RNmean)) / RNpop)

gross_vals <- data.table(pop = RBpop,
 mean = coef(RBmean),
  se = SE(RBmean),
  dif = (RBpop - coef(RBmean)) / RBpop)
results <- rbind(net_vals, gross_vals, use.names = FALSE) %>% print()
