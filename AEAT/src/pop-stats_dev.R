# Obtain population statistics for AEAT subsample

# Clean environment to avoid RAM bottlenecks and import dependencies

rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
library(dineq)
source("AEAT/src/etl_pipe.R")

# Import needed data objects

represet <- "!is.na(FACTORCAL)" # población
represet2 <- 'TIPODEC %in% c("T1", "T21") & !is.na(FACTORCAL)' # declarantes de renta
sel_year <- 2016
ref_unit <- "IDENHOG"
risks <- fread("AEAT/data/risk.csv")
dt <- get_wave(sel_year = sel_year, ref_unit = ref_unit, represet = represet)

# Prepare survey object from dt and set income cuts for quantiles dynamically
dt_pre <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL) # muestra con coeficientes de elevación
dt_sv <- subset(dt_pre, MUESTRA == 5) # subset for a given city
quantiles <- seq(.25, .75, .25) # cortes
quantiles_renta <- svyquantile(~RENTAD, design = dt_sv, quantiles = quantiles, ci = FALSE)$RENTAD # rentas asociadas a cores
table_names <- c(
    paste0("hasta ", quantiles_renta[, "0.25"]),
    paste0("entre ", quantiles_renta[, "0.25"], " y ", quantiles_renta[, "0.5"]),
    paste0("entre ", quantiles_renta[, "0.5"], " y ", quantiles_renta[, "0.75"]),
    paste0("mas de ", quantiles_renta[, "0.75"])
)


########################################################

# TABLA 1: Use svytable and prop.table to get proportions of TENENCIA across income quantiles
tenencia25 <- svytable(~TENENCIA, subset(dt_sv, RENTAD < quantiles_renta[, "0.25"])) %>% prop.table()
tenencia25to50 <- svytable(~TENENCIA, subset(dt_sv, RENTAD > quantiles_renta[, "0.25"] & RENTAD < quantiles_renta[, "0.5"])) %>% prop.table()
tenencia50to75 <- svytable(~TENENCIA, subset(dt_sv, RENTAD > quantiles_renta[, "0.5"] & RENTAD < quantiles_renta[, "0.75"])) %>% prop.table()
tenencia75 <- svytable(~TENENCIA, subset(dt_sv, RENTAD > quantiles_renta[, "0.75"])) %>% prop.table()

# Combine the proportions into one data.table
final_table <- rbind(
    data.table(niveles = table_names[1], tenencia25),
    data.table(niveles = table_names[2], tenencia25to50),
    data.table(niveles = table_names[3], tenencia50to75),
    data.table(niveles = table_names[4], tenencia75)
)

########################################################

caseros25 <- svytable(~CASERO, subset(dt_sv, RENTAD < quantiles_renta[, "0.25"]))
caseros25to50 <- svytable(~CASERO, subset(dt_sv, RENTAD > quantiles_renta[, "0.25"] & RENTAD < quantiles_renta[, "0.5"]))
caseros50to75 <- svytable(~CASERO, subset(dt_sv, RENTAD > quantiles_renta[, "0.5"] & RENTAD < quantiles_renta[, "0.75"]))
caseros75 <- svytable(~CASERO, subset(dt_sv, RENTAD > quantiles_renta[, "0.75"]))

inquilinos25 <- svytable(~INQUILINO, subset(dt_sv, RENTAD < quantiles_renta[, "0.25"]))
inquilinos25to50 <- svytable(~INQUILINO, subset(dt_sv, RENTAD > quantiles_renta[, "0.25"] & RENTAD < quantiles_renta[, "0.5"]))
inquilinos50to75 <- svytable(~INQUILINO, subset(dt_sv, RENTAD > quantiles_renta[, "0.5"] & RENTAD < quantiles_renta[, "0.75"]))
inquilinos75 <- svytable(~INQUILINO, subset(dt_sv, RENTAD > quantiles_renta[, "0.75"]))

caseros <- data.table(rbind(caseros25, caseros25to50, caseros50to75, caseros75))[, "1"] %>% prop.table()
inquilinos <- data.table(rbind(inquilinos25, inquilinos25to50, inquilinos50to75, inquilinos75))[, "1"] %>% prop.table()
final_table2 <- cbind(table_names, caseros, inquilinos)
colnames(final_table2) <- c("niveles", "caseros", "inquilinos")