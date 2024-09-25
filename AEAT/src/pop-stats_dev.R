# Obtain population statistics for AEAT subsample

# clean enviroment to avoid ram botltenecks and import dependencies

rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
library(dineq)
source("AEAT/src/etl_pipe.R")

# import needed data objects
represet <- "!is.na(FACTORCAL)" # población
represet2 <- 'TIPODEC %in% c("T1", "T21") & !is.na(FACTORCAL)' # declarantes de renta
sel_year <- 2016
ref_unit <- "IDENHOG"
risks <- fread("AEAT/data/risk.csv")
dt <- get_wave(sel_year = sel_year, ref_unit = ref_unit, represet = represet)

# hardcoded varssç

net_var <- colnames(risks)[colnames(risks) %like% tolower(ref_unit)]
risk_pov_tier <- risks[year == sel_year, get(net_var)]
dt[, RISK := 0][RENTAD < risk_pov_tier, RISK := 1]
dt[, CASERO2 := 0][RENTA_ALQ > 1200, CASERO2 := 1]

# Create the survey design object with the initial weights

survey_design <- svydesign(
    ids = ~1,
    data = dt,
    weights = dt$FACTORCAL
)

# Subsample for a reference municipio

subsample <- subset(survey_design, MUESTRA == 1)

# obtain quantiles for a given variable

quantiles <- svyquantile(~RENTA_ALQ, subsample, quantiles = c(0.1, 0.25, 0.5, 0.75, 0.90, 0.95, 0.99))

svyhist(~NPROP_ALQ, design = subsample, breaks = 30) %>% print()
