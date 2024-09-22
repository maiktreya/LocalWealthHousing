# Obtain t-statisctics for representative mean forAEAT subsample

library(survey)
library("magrittr")
rm(list = ls()) # clean enviroment to avoid ram bottlenecks
source("AEAT/src/etl_pipe.R")

# import population distributional values

pop_stats <- fread("AEAT/data/pop-stats.csv")
municipios <- cbind(mun = c("segovia", "lastrilla", "sancris", "palazuelos"), ind = c(1:4)) %>% data.table()
seleccion <- "segovia"

get_col <- colnames(pop_stats)[colnames(pop_stats) %like% tolower(ref_unit)]
RNpop <- pop_stats[muni == seleccion & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]
RBpop <- pop_stats[muni == seleccion & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]

# Create the survey design object with the initial weights

survey_design <- svydesign(
    ids = ~1,
    data = dt,
    weights = dt$FACTORCAL
)
subsample <- subset(survey_design, MUESTRA == municipios[mun == seleccion]$ind)

# performe representativness test on key variables with known distributional values

RNmean <- svymean(~RENTAD, subsample)
RBmean <- svymean(~RENTAB, subsample)

test_rep1 <- svyttest(I(RENTAD - RNpop) ~ 0, subsample) %>% print()
test_rep2 <- svyttest(I(RENTAB - RBpop) ~ 0, subsample) %>% print()

test_conf1 <- confint(test_rep1, level = 0.95) %>% print()
test_conf2 <- confint(test_rep2, level = 0.95) %>% print()

net_vals <- data.table(pop = RNpop, mean = RNmean, dif = (RNpop - RNmean) / RNpop)
gross_vals <- data.table(pop = RBpop, mean = RBmean, dif = (RBpop - RBmean) / RBpop)
results <- rbind(net_vals, gross_vals) %>% print()
