# clean enviroment and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")
pop_stats <- fread("AEAT/data/pop-stats.csv")
dt <- fread("AEAT/data/madridIDENHOG2021.gz")

###### New variables definitions
dt[, TIPO_PROP := fcase(
    NPROP_ALQ == 1, "1",
    NPROP_ALQ == 2, "2",
    NPROP_ALQ == 3, "3",
    NPROP_ALQ == 4, "4",
    NPROP_ALQ > 4, "5+",
    default = "0"
)]

####### Prepare data as survey object

dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL)

####### Perform calculations to obtain sample statistics

caseros_total <- svyquantile(~NPROP_ALQ, subset(dt_sv, NPROP_ALQ > 0), quantiles = seq(0, 1, by = 0.05)) %>%
    print()
prop_caseros <- svytotal(~TIPO_PROP, dt_sv) %>%
    prop.table() %>%
    round(3) %>%
    print()
conc_rentistas <- svyby(~NPROP_ALQ, ~TIPO_PROP, subset(dt_sv, NPROP_ALQ > 0), svytotal)[2] %>%
    prop.table() %>%
    round(3) %>%
    print()
conc_caseros <- svyby(~RENTA_ALQ2, ~TIPO_PROP, subset(dt_sv, NPROP_ALQ > 0), svytotal)[2] %>%
    prop.table() %>%
    round(3) %>%
    print()
rent_prop <- svymean(~RENTA_ALQ2, subset(dt_sv, RENTA_ALQ2 > 0)) %>%
    round(3) %>%
    print()
props <- svymean(~NPROP, subset(dt_sv, NPROP > 0)) %>%
    round(3) %>%
    print()
props_alq <- svymean(~NPROP_ALQ, subset(dt_sv, NPROP_ALQ > 0)) %>%
    print()
