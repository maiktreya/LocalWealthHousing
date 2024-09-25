# Obtain population statistics for AEAT subsample

# Clean environment to avoid RAM bottlenecks and import dependencies

rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
library(dineq)
source("AEAT/src/transform/etl_pipe.R")

# Import needed data objects

represet <- "!is.na(FACTORCAL)" # población
represet2 <- 'TIPODEC %in% c("T1", "T21") & !is.na(FACTORCAL)' # declarantes de renta
sel_year <- 2016
ref_unit <- "IDENHOG"
risks <- fread("AEAT/data/risk.csv")
dt <- get_wave(sel_year = sel_year, ref_unit = ref_unit, represet = represet)

# Prepare survey object from dt and set income cuts for quantiles dynamically
dt_pre <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL) # muestra con coeficientes de elevación
dt_sv <- subset(dt_pre, MUESTRA == "Madrid") # subset for a given city
quantiles <- seq(.25, .75, .25) # cortes
quantiles_renta <- svyquantile(~RENTAD, design = dt_sv, quantiles = quantiles, ci = FALSE)$RENTAD # rentas asociadas a cores
table_names <- c(
    paste0("hasta ", quantiles_renta[, "0.25"]),
    paste0("entre ", quantiles_renta[, "0.25"], " y ", quantiles_renta[, "0.5"]),
    paste0("entre ", quantiles_renta[, "0.5"], " y ", quantiles_renta[, "0.75"]),
    paste0("mas de ", quantiles_renta[, "0.75"])
)


########################################################
