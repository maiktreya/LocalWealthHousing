# Obtain t-statisctics for representative mean for AEAT subsample

rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")




# define city subsample and variables to analyze

city <- "Segovia"
represet <- "!is.na(FACTORCAL)" # población
represet2 <- 'TIPODEC %in% c("T1", "T21") & !is.na(FACTORCAL)' # declarantes de renta
sel_year <- 2016
ref_unit <- "IDENHOG"
pop_stats <- fread("AEAT/data/pop-stats.csv")
RNpop <- pop_stats[muni == tolower(city) & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]
RBpop <- pop_stats[muni == tolower(city) & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]
dt <- get_wave(sel_year = sel_year, ref_unit = ref_unit, represet = represet)

## Prepare survey object from dt and set income cuts for quantiles dynamically

dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL) # muestra con coeficientes de elevación
subsample <- subset(dt_sv, MUESTRA == city) # subset for a given city

# calculate sample means

RNmean <- svymean(~RENTAD, subsample)
RBmean <- svymean(~RENTAB, subsample)

# Test sample means against true population means

test_rep1 <- svyttest(I(RENTAD - RNpop) ~ 0, subsample) %>% print()
test_rep2 <- svyttest(I(RENTAB - RBpop) ~ 0, subsample) %>% print()

# Obtain confidence intervals

test_conf1 <- confint(test_rep1, level = 0.95) %>% print()
test_conf2 <- confint(test_rep2, level = 0.95) %>% print()


# Summarize the results

net_vals <- data.table(pop = RNpop, mean = RNmean, dif = (RNpop - RNmean) / RNpop)
gross_vals <- data.table(pop = RBpop, mean = RBmean, dif = (RBpop - RBmean) / RBpop)
results <- rbind(net_vals, gross_vals) %>% print()
