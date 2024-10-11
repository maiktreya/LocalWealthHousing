# clean enviroment and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")
pop_stats <- fread("AEAT/data/pop-stats.csv")
dt <- fread("AEAT/data/madridIDENHOG2021.gz")

######

dt[, NPROP_ALQ2 := as.factor(NPROP_ALQ)]
dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL)

caseros_total <- svytotal(~NPROP_ALQ2, dt_sv) %>%
    prop.table() %>%
    round(3)

prop_caseros <- svytotal(~NPROP_ALQ2, dt_sv) %>%
    prop.table() %>%
    round(3)
