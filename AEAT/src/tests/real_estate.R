# clean enviroment and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")
pop_stats <- fread("AEAT/data/pop-stats.csv")
dt <- fread("AEAT/data/madridIDENHOG2016.gz")

###### New variables definitions
dt[, TIPO_PROP := fcase(
    NPROP_ALQ == 1, "1",
    NPROP_ALQ == 2, "2",
    NPROP_ALQ == 3, "3",
    NPROP_ALQ == 4, "4",
    NPROP_ALQ > 4, "5+",
    default = "0"
)]
dt[, INC_PER_PROP := 0][RENTA_ALQ2 > 0, INC_PER_PROP := RENTA_ALQ2 / NPROP_ALQ]

####### Prepare data as survey object

dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL)

####### Perform calculations to obtain sample statistics

prop_caseros <- svytable(~TIPO_PROP, dt_sv) %>%
    prop.table() %>%
    round(3) %>%
    data.table()
conc_rentistas <- svyby(~NPROP_ALQ, ~TIPO_PROP, subset(dt_sv, NPROP_ALQ > 0, ci = FALSE), svytotal)[2] %>%
    prop.table() %>%
    round(3)
conc_caseros <- svyby(~RENTA_ALQ2, ~TIPO_PROP, subset(dt_sv, NPROP_ALQ > 0), svytotal)[2] %>%
    prop.table() %>%
    round(3)

ave_income <- svyby(~RENTA_ALQ2, ~TIPO_PROP, subset(dt_sv, RENTA_ALQ2 > 0), svymean)[2] %>%
    round(3) %>%
    print()
ave_income_per_prop <- svyby(~INC_PER_PROP, ~TIPO_PROP, subset(dt_sv, RENTA_ALQ2 > 0), svymean)[2] %>%
    round(3) %>%
    print()

caseros_total <- svyquantile(~NPROP_ALQ, subset(dt_sv, NPROP_ALQ > 0), quantiles = c(seq(.5, .95, by = 0.05), .99))$NPROP_ALQ[, 1] %>%
    print()
rent_prop <- svymean(~RENTA_ALQ2, subset(dt_sv, RENTA_ALQ2 > 0))[1] %>%
    round(3) %>%
    print()
med_rent_prop <- svyquantile(~RENTA_ALQ2, subset(dt_sv, RENTA_ALQ2 > 0), quantiles = .5)$RENTA_ALQ2[, 1] %>%
    print()
props_alq <- svymean(~NPROP_ALQ, subset(dt_sv, NPROP_ALQ > 0))[1] %>%
    print()

results <- cbind(prop_caseros[-1], conc_rentistas, conc_caseros, ave_income, ave_income_per_prop)
pob_inq <- data.table(TIPO_PROP = "no_caseros", N = prop_caseros$N[1], NPROP_ALQ = 0, RENTA_ALQ2 = 0, RENTA_ALQ2 = 0, INC_PER_PROP = 0)

results <- rbind(results, pob_inq)
colnames(results) <- c(
    "Nº propiedades alquiladas",
    "% total de hogares",
    "% total de viviendas",
    "% total rentas del alquiler",
    "ingresos_medios alquiler",
    "ingresos medios por inmueble"
)
print(results)
