# Obtain population statistics for AEAT subsample

# Clean environment to avoid RAM bottlenecks and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")

# define control parameters
city <- "madrid"
represet <- "!is.na(FACTORCAL)"
sel_year <- 2021
ref_unit <- "IDENHOG"
ref_pop <- fread(paste0("AEAT/data/base/", city, "-sex.csv"))[year == sel_year, total]
city_index <- fread("AEAT/data/pop-stats.csv")[muni == city & year == sel_year, index]

# get subsample
dt <- get_wave(
    city = city,
    sel_year = sel_year,
    ref_unit = ref_unit,
    represet = represet,
    calibrated = TRUE,
    raked = TRUE # Working just for Madrid & Segovia cities
)

# Prepare survey object from dt and set income cuts for quantiles dynamically
dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL) # muestra con coeficientes de elevación
dt_sv <- subset(dt_sv, MUESTRA == city_index) # subset for a given city
quantiles <- seq(.25, .75, .25) # cortes
quantiles_renta <- svyquantile(~RENTAD, design = dt_sv, quantiles = quantiles, ci = FALSE)$RENTAD # rentas asociadas a cores
table_names <- c(
    paste0("hasta ", quantiles_renta[, "0.25"]),
    paste0("entre ", quantiles_renta[, "0.25"], " y ", quantiles_renta[, "0.5"]),
    paste0("entre ", quantiles_renta[, "0.5"], " y ", quantiles_renta[, "0.75"]),
    paste0("mas de ", quantiles_renta[, "0.75"])
)

# TABLA 1: Use svytable and prop.table to get proportions of TENENCIA across income quantiles
tenencia25 <- svytable(~TENENCIA, subset(dt_sv, RENTAD < quantiles_renta[, "0.25"]))
tenencia25to50 <- svytable(~TENENCIA, subset(dt_sv, RENTAD > quantiles_renta[, "0.25"] & RENTAD < quantiles_renta[, "0.5"]))
tenencia50to75 <- svytable(~TENENCIA, subset(dt_sv, RENTAD > quantiles_renta[, "0.5"] & RENTAD < quantiles_renta[, "0.75"]))
tenencia75 <- svytable(~TENENCIA, subset(dt_sv, RENTAD > quantiles_renta[, "0.75"]))

# Combine the proportions into one data.table
final_table <- rbind(tenencia25, tenencia25to50, tenencia50to75, tenencia75)
for (i in 1:ncol(final_table)) final_table[, i] <- prop.table(final_table[, i]) # nolint
final_table <- cbind(quantiles = table_names, final_table)

# TABLA 2: Calculate the median and mean income for each TENENCIA group
renta_stats <- svyby(~RENTAD, ~TENENCIA, design = dt_sv, FUN = svyquantile, quantiles = 0.5)
mean_renta_stats <- svyby(~RENTAD, ~TENENCIA, design = dt_sv, FUN = svymean)

# Combine median and mean tables
renta_table <- data.table(
    TENENCIA = renta_stats$TENENCIA,
    media = mean_renta_stats$RENTAD,
    mediana = renta_stats$RENTAD
)

# TABLA 3: Calculate total frequencies by TENENCIA using svytable
tenencia_freq <- data.table(svytable(~TENENCIA, dt_sv, Ntotal = ref_pop))
tenencia_prop <- prop.table(svytable(~TENENCIA, dt_sv, Ntotal = ref_pop))
tenencia_table <- cbind(tenencia_freq, tenencia_prop)

# Check output
list(final_table, renta_table, tenencia_freq) %>% print()

# Export to AEAT/out folder our tables of results
fwrite(final_table, paste0("AEAT/out/", city, "-", sel_year, "-", ref_unit, "tabla-quantiles.csv"))
fwrite(renta_table, paste0("AEAT/out/", city, "-", sel_year, "-", ref_unit, "tabla-renta.csv"))
fwrite(tenencia_table, paste0("AEAT/out/", city, "-", sel_year, "-", ref_unit, "reg_tenencia.csv"))
