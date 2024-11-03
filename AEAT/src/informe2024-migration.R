# clean enviroment and import dependencies
rm(list = ls())
gc(full = TRUE, verbose = TRUE)
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")
pop_stats <- fread("AEAT/data/pop-stats.csv")

# define city subsample and variables to analyze
city <- "segovia"
represet <- "!is.na(FACTORCAL)"
sel_year <- 2016
ref_unit <- "IDENHOG"
calibrated <- TRUE

# get a sample weighted for a given city
dt <- get_wave(
    city = city, # subregional unit
    sel_year = sel_year, # wave
    ref_unit = ref_unit, # reference PSU (either household or individual)
    represet = represet, # reference universe/population (whole pop. or tax payers)
    calibrated = calibrated, # Weight calib. (TRUE/FALS)E Requieres auxiliary  data
)

# ensure subsample of interest is selected in case calibration is not applied
dt <- subset(dt, MUESTRA == pop_stats[muni == city & year == sel_year, index])

###### New variables definitions
dt[, TIPO_PROP := fcase(
    default = NA,
    NPROP_ALQ == 1, "1",
    NPROP_ALQ %in% c(2, 3, 4), "2-4",
    NPROP_ALQ > 4, "5+"
)]
dt[, NACIO := as.factor(NACIO)]
dt[, MIGR := 0][NACIO != 108, MIGR := 1][, MIGR := as.factor(MIGR)]

# Prepare data as survey object
dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL)

# Compute summary statistics

renta_ten_mig <- coef(svyby(~RENTAD, ~TENENCIA, subset(dt_sv, MIGR == 1), svymean))
renta_ten_nat <- coef(svyby(~RENTAD, ~TENENCIA, subset(dt_sv, MIGR == 0), svymean))
tenencia_migr <- coef(svymean(~TENENCIA, subset(dt_sv, MIGR == 1)))
tenencia_nacio <- coef(svymean(~TENENCIA, subset(dt_sv, MIGR == 0)))

tipo_prop <- coef(svyby(~TIPO_PROP, ~MIGR, dt_sv, svytotal, na.rm = TRUE))

miembros <- c(
    coef(svymean(~MIEMBROS, subset(dt_sv, MIGR == 0))),
    coef(svymean(~MIEMBROS, subset(dt_sv, MIGR == 1))),
    coef(svymean(~MIEMBROS, dt_sv))
)

tipo_prop <- cbind(tipo_prop[c(1, 3, 5)], tipo_prop[c(2, 4, 6)]) %>% print()
renta <- c(coef(svyby(~RENTAD, ~MIGR, dt_sv, svymean)), coef(svymean(~RENTAD, dt_sv))) %>% print()
prop_migr <- c(coef(svymean(~MIGR, dt_sv)), tot = 1) %>% print()
tenencia <- cbind(tenencia_migr, tenencia_nacio) %>% print()
renta_tenencia <- cbind(renta_ten_mig, renta_ten_nat) %>% print()

results <- cbind(tipo_prop, renta, prop_migr, tenencia, renta_tenencia, miembros)

fwrite(results, paste0("AEAT/out/", city, "/", city, "-", sel_year, "-", ref_unit, "migr.csv"))
