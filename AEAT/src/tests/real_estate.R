# clean enviroment and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")
pop_stats <- fread("AEAT/data/pop-stats.csv")
dt <- fread("AEAT/data/madridIDENHOG2021.gz")

###### New variables definitions

dt[, NPROP_ALQ2 := as.factor(NPROP_ALQ)]
dt[RENTA_ALQ2 > 0, RENT_PROP := RENTA_ALQ2 / NPROP_ALQ]

####### Prepare data as survey object

dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL)

####### Perform calculations to obtain sample statistics

caseros_total <- svytotal(~NPROP_ALQ2, dt_sv) %>%
    prop.table() %>%
    round(3) %>%
    print()

prop_caseros <- svytotal(~NPROP_ALQ2, dt_sv) %>%
    prop.table() %>%
    round(3) %>%
    print()
rent_prop <- svttotal(~RENT_PROP, dt_sv) %>%
    round(3) %>%
    print()
