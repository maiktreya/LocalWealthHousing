# Obtain population statistics for AEAT subsample

# clean enviroment to avoid ram bottlenecks and import dependencies

rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")

# Import needed data objects
city <- "madrid"
represet <- "!is.na(FACTORCAL)"
sel_year <- 2016
ref_unit <- "IDENHOG"
city_index <- fread("AEAT/data/pop-stats.csv")[muni == city & year == sel_year, index]
dt <- get_wave(sel_year = sel_year, ref_unit = ref_unit, represet = represet)

## Prepare survey object from dt and set income cuts for quantiles dynamically
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


# TABLA 1-------------------------------------------------------------------------------
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
final_table <- cbind(table_names, caseros, inquilinos)
colnames(final_table) <- c("niveles", "caseros", "inquilinos")


# TABLA 2--------------------------------------------------------------------
median_renta_inquili <- svyquantile(~RENTAD, subset(dt_sv, INQUILINO == 1), quantiles = .5, ci = FALSE)$RENTAD[1]
median_renta_caseros <- svyquantile(~RENTAD, subset(dt_sv, CASERO == 1), quantiles = .5, ci = FALSE)$RENTAD[1]
median_renta_propsin <- svyquantile(~RENTAD, subset(dt_sv, PROPIETARIO == 1), quantiles = .5, ci = FALSE)$RENTAD[1]
median_renta_totalpo <- svyquantile(~RENTAD, dt_sv, quantiles = .5, ci = FALSE)$RENTAD[1]
median_renta_caseros_NOAL <- svyquantile(~RENTAD_NOAL, subset(dt_sv, CASERO == 1), quantiles = .5, ci = FALSE)$RENTAD_NOAL[1]

mean_renta_inquili <- svymean(~RENTAD, subset(dt_sv, INQUILINO == 1))[1]
mean_renta_caseros <- svymean(~RENTAD, subset(dt_sv, CASERO == 1))[1]
mean_renta_caseros_NOAL <- svymean(~RENTAD_NOAL, subset(dt_sv, CASERO == 1))[1]
mean_renta_propsin <- svymean(~RENTAD, subset(dt_sv, PROPIETARIO == 1))[1]
mean_renta_totalpo <- svymean(~RENTAD, dt_sv)[1]

medians <- c(median_renta_caseros, median_renta_caseros_NOAL, median_renta_inquili, median_renta_propsin, median_renta_totalpo)
means <- c(mean_renta_caseros, mean_renta_caseros_NOAL, mean_renta_inquili, mean_renta_propsin, mean_renta_totalpo)
renta_table <- cbind(c("caseros", "caseros (excluye rentas alq.)", "inquilinos", "prop. sin rentas alq.", "todos"), means, medians)
colnames(renta_table) <- c("tipo", "media", "mediana")

# TABLA 3-----------------------------------------------------------------------
# Calculate frequencies with survey weights, only including cases where the variable equals 1
CASERO_FREQ <- svytotal(~CASERO, design = dt_sv, subset = CASERO == 1)[-1]
INQUILINO_FREQ <- svytotal(~INQUILINO, design = dt_sv, subset = INQUILINO == 1)[-1]
PROPIETARIO_FREQ <- svytotal(~PROPIETARIO, design = dt_sv, subset = PROPIETARIO == 1)[-1]

# Create a data frame
reg_tenencia <- data.frame(
    Category = c("CASERO", "INQUILINO", "PROPIETARIO"),
    Frequency = c(CASERO_FREQ, INQUILINO_FREQ, PROPIETARIO_FREQ)
)

reg_tenencia <- reg_tenencia %>%
    dplyr::mutate(Percentage = (Frequency / sum(Frequency)) * 100)


# Check AEAT/output
list(final_table, renta_table, reg_tenencia) %>% print()

# Export to AEAT/out folder our tables of results
fwrite(final_table, paste0("AEAT/out/", city, "-", sel_year, "-", ref_unit, "tabla-quantiles2.csv"))
fwrite(renta_table, paste0("AEAT/out/", city, "-", sel_year, "-", ref_unit, "tabla-renta2.csv"))
fwrite(tenencia_table, paste0("AEAT/out/", city, "-", sel_year, "-", ref_unit, "reg_tenencia2.csv"))
