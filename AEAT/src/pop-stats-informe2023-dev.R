# Obtain population statistics for AEAT subsample

# clean environment to avoid RAM bottlenecks and import dependencies

rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
library(dineq)
source("AEAT/src/etl_pipe.R")

# import microdata and define hardcoded variables

represet <- "!is.na(FACTORCAL)" # población
represet2 <- 'TIPODEC %in% c("T1", "T21") & !is.na(FACTORCAL)' # declarantes de renta
sel_year <- 2016 # año de la muestra
ref_unit <- "IDENHOG" # hogares o personas
risks <- fread("AEAT/data/risk.csv")
dt <- get_wave(sel_year = sel_year, ref_unit = ref_unit, represet = represet)


# Prepare survey object from dt and set income cuts for quantiles dynamically

dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL) # muestra con coeficientes de elevación
dt_sv <- subset(dt_sv, MUESTRA == 1) # Subsample for a reference municipio
quantiles <- seq(.25, .75, .25) # cortes
quantiles_renta <- svyquantile(~RENTAD, design = dt_sv, quantiles = quantiles, ci = FALSE)$RENTAD # rentas asociadas a cores
table_names <- c(
    paste0("hasta ", quantiles_renta[, "0.25"]),
    paste0("entre ", quantiles_renta[, "0.25"], " y ", quantiles_renta[, "0.5"]),
    paste0("entre ", quantiles_renta[, "0.5"], " y ", quantiles_renta[, "0.75"]),
    paste0("mas de ", quantiles_renta[, "0.75"])
)

# TABLA 1-------------------------------------------------------------------------------

tenencia25 <- svytable(~TENENCIA, subset(dt_sv, RENTAD < quantiles_renta[, "0.25"])) %>% data.table()
tenencia25to50 <- svytable(~TENENCIA, subset(dt_sv, RENTAD > quantiles_renta[, "0.25"] & RENTAD < quantiles_renta[, "0.5"])) %>% data.table()
tenencia50to75 <- svytable(~TENENCIA, subset(dt_sv, RENTAD > quantiles_renta[, "0.5"] & RENTAD < quantiles_renta[, "0.75"])) %>% data.table()
tenencia75 <- svytable(~TENENCIA, subset(dt_sv, RENTAD > quantiles_renta[, "0.75"])) %>% data.table()
tenencia25[, Freq := N]
tenencia25to50[, Freq := N]
tenencia50to75[, Freq := N]
tenencia75[, Freq := N]
tenencia <- rbind(tenencia25, tenencia25to50, tenencia50to75, tenencia75)[, .(Freq = sum(Freq)), by = TENENCIA]
tenencia[, Proportion := Freq / sum(Freq)]  # Calculate proportions
final_table <- cbind(table_names, tenencia)
colnames(final_table) <- c("niveles", "tenencia", "frecuencia", "proporción")


# TABLA 2--------------------------------------------------------------------

median_renta_tenencia <- svyquantile(~RENTAD, dt_sv, quantiles = .5, ci = FALSE)$RENTAD
mean_renta_tenencia <- svymean(~RENTAD, dt_sv)
medians <- c(median_renta_tenencia)
means <- c(mean_renta_tenencia)
renta_table <- cbind(c("todos"), means, medians)
colnames(renta_table) <- c("tipo", "media", "mediana")

# TABLA 3-----------------------------------------------------------------------

tenencia_freq <- svytotal(~TENENCIA, design = dt_sv)
reg_tenencia <- data.table(
    Category = names(tenencia_freq),
    Frequency = as.numeric(tenencia_freq)
)
reg_tenencia[, Percentage := (Frequency / sum(Frequency)) * 100]

# Check AEAT/output

list(final_table, renta_table, reg_tenencia) %>% print()

# Export AEAT/out

fwrite(final_table, paste0("AEAT/out/", sel_year, "-", ref_unit, "tabla-quantiles2.csv"))
fwrite(renta_table, paste0("AEAT/out/", sel_year, "-", ref_unit, "tabla-renta2.csv"))
fwrite(reg_tenencia, paste0("AEAT/out/", sel_year, "-", ref_unit, "reg_tenencia2.csv"))
