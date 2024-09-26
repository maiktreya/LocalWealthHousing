# Obtain t-statisctics for representative mean for AEAT subsample

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
RNpop <- pop_stats[muni == city & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]
RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]
dt <- get_wave(sel_year = sel_year, ref_unit = ref_unit, represet = represet)

## Prepare survey object from dt and set income cuts for quantiles dynamically

dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL) # muestra con coeficientes de elevación
subsample <- subset(dt_sv, CIUDAD == city) # subset for a given city

# calculate sample means

RNmean <- svymean(~RENTAD, subsample)
RBmean <- svymean(~RENTAB, subsample)

# Test sample means against true population means

test_rep1 <- svyttest(I(RENTAD - RNpop) ~ 0, subsample) %>% print()
test_rep2 <- svyttest(I(RENTAB - RBpop) ~ 0, subsample) %>% print()

# Summarize the results

net_vals <- data.table(pop = RNpop, mean = RNmean, dif = (RNpop - RNmean) / RNpop)
gross_vals <- data.table(pop = RBpop, mean = RBmean, dif = (RBpop - RBmean) / RBpop)
results <- rbind(net_vals, gross_vals) %>% print()
