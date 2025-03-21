# Obtain population statistics for AEAT subsample

# clean enviroment and import dependencies
rm(list = ls())
gc(full = TRUE, verbose = TRUE)
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")

for (i in c("madrid")) {
    city <- i
    for (j in c(2016, 2021)) {
        sel_year <- j
        for (k in c("IDENHOG")) {
            # define city subsample and variables to analyze
            calib_mode <- TRUE
            ref_unit <- k # reference PSU (either household or individual)
            represet <- "!is.na(FACTORCAL)" #  universe, households (default) or tax payers
            pop_stats <- fread("AEAT/data/pop-stats.csv")

            # get a sample weighted for a given city
            dt <- get_wave(
                city = city, # subregional unit
                sel_year = sel_year, # wave
                ref_unit = ref_unit, # reference PSU (either household or individual)
                calibrated = calib_mode, # Weight calib. (TRUE, FALSE) Requieres auxiliary total/mean data
            )

            # Prepare survey object from dt and set income cuts for quantiles dynamically
            dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL) # muestra con coeficientes de elevación
            dt_sv <- subset(dt_sv, MUESTRA == pop_stats[muni == city & year == sel_year, index]) # subset for a given city
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
            renta_stats <- svyby(~RENTAD, ~TENENCIA, design = dt_sv, FUN = svyquantile, quantiles = .5)
            mean_renta_stats <- svyby(~RENTAD, ~TENENCIA, design = dt_sv, FUN = svymean)
            mean_renta_stats_noal <- svyby(~RENTAD_NOAL, ~TENENCIA, design = dt_sv, FUN = svymean)
            medi_renta_stats_noal <- svyby(~RENTAD_NOAL, ~TENENCIA, design = dt_sv, FUN = svyquantile, quantiles = .5)

            # Combine median and mean tables
            renta_table <- data.table(
                TENENCIA = renta_stats$TENENCIA,
                media = mean_renta_stats$RENTAD,
                mediana = renta_stats$RENTAD,
                media_noal = mean_renta_stats_noal$RENTAD_NOAL,
                mediana_noal = medi_renta_stats_noal$RENTAD_NOAL
            )

            # TABLA 3: Calculate total frequencies by TENENCIA using svytable
            tenencia_freq <- data.table(svytable(~TENENCIA, dt_sv, Ntotal = sum(weights(dt_sv))))
            tenencia_prop <- prop.table(svytable(~TENENCIA, dt_sv, Ntotal = sum(weights(dt_sv))))
            tenencia_table <- cbind(tenencia_freq, tenencia_prop)

            # Check output
            list(final_table, renta_table, tenencia_freq) %>% print()

            # Export to AEAT/out folder our tables of results
            fwrite(final_table, paste0("AEAT/out/", city, "/", city, "-", sel_year, "-", ref_unit, "tabla-quantiles.csv"))
            fwrite(renta_table, paste0("AEAT/out/", city, "/", city, "-", sel_year, "-", ref_unit, "tabla-renta.csv"))
            fwrite(tenencia_table, paste0("AEAT/out/", city, "/", city, "-", sel_year, "-", ref_unit, "reg_tenencia.csv"))
        }
    }
}
