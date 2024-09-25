# Obtain population statistics for AEAT subsample

# clean environment to avoid RAM bottlenecks and import dependencies
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
dt <- get_wave(sel_year = sel_year, ref_unit = ref_unit, represet = represet2)

# Modify the ownership variables to create a single categorical variable 'TENENCIA'
dt[, TENENCIA := "INQUILINA"]
dt[PAR150 > 0, TENENCIA := "CASERO"]
dt[PATINMO > 0 & TENENCIA != "CASERO", TENENCIA := "PROPIETARIO"]
dt[, TENENCIA := factor(TENENCIA)]

# Prepare survey object from dt and set income cuts for quantiles dynamically
dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL) # muestra con coeficientes de elevación
quantiles <- seq(.25, .75, .25) # cortes
quantiles_renta <- svyquantile(~RENTAD, design = dt_sv, quantiles = quantiles, ci = FALSE)$RENTAD # rentas asociadas a cores
table_names <- c(
    paste0("hasta ", quantiles_renta[, "0.25"]),
    paste0("entre ", quantiles_renta[, "0.25"], " y ", quantiles_renta[, "0.5"]),
    paste0("entre ", quantiles_renta[, "0.5"], " y ", quantiles_renta[, "0.75"]),
    paste0("mas de ", quantiles_renta[, "0.75"])
)

# Use svyby to get the counts and proportions by TENENCIA and income quantiles
tenencia_quantiles <- svyby(~TENENCIA, by = ~cut(RENTAD, breaks = quantiles_renta), design = dt_sv, svytotal, vartype = "ci")

# Convert svyby result to a data.table
tenencia_dt <- as.data.table(tenencia_quantiles)

# Renaming columns to make the output more understandable
setnames(tenencia_dt, old = c("cut(RENTAD, breaks = quantiles_renta)"), new = "income_level")

# Calculate the proportions within each income quantile
tenencia_dt[, Proportion := Total / sum(Total), by = income_level]

# Prepare final table
final_table <- tenencia_dt[, .(income_level, TENENCIA, Total, Proportion)]
setnames(final_table, old = c("Total", "Proportion"), new = c("frecuencia", "proporción"))

# TABLA 2--------------------------------------------------------------------
# Calculate the median and mean income for each TENENCIA group
renta_stats <- svyby(~RENTAD, ~TENENCIA, design = dt_sv, FUN = svyquantile, quantiles = 0.5, ci = FALSE)
mean_renta_stats <- svyby(~RENTAD, ~TENENCIA, design = dt_sv, FUN = svymean)

# Combine median and mean tables
renta_table <- data.table(
    TENENCIA = renta_stats$TENENCIA,
    media = mean_renta_stats$RENTAD,
    mediana = renta_stats$RENTAD
)

# TABLA 3-----------------------------------------------------------------------
# Calculate total frequencies by TENENCIA
reg_tenencia <- svyby(~TENENCIA, ~TENENCIA, design = dt_sv, FUN = svytotal)

# Convert svyby result to data.table for easier manipulation
reg_tenencia_dt <- as.data.table(reg_tenencia)

# Calculate percentages
reg_tenencia_dt[, Percentage := Total / sum(Total) * 100]

# Check AEAT/output
list(final_table, renta_table, reg_tenencia_dt) %>% print()

# Export AEAT/out
fwrite(final_table, paste0("AEAT/out/", sel_year, "-", ref_unit, "tabla-quantiles2.csv"))
fwrite(renta_table, paste0("AEAT/out/", sel_year, "-", ref_unit, "tabla-renta2.csv"))
fwrite(reg_tenencia_dt, paste0("AEAT/out/", sel_year, "-", ref_unit, "reg_tenencia2.csv"))
