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
    default = "0",
    NPROP_ALQ == 1, "1",
    NPROP_ALQ >= 2, "2+"
)]
dt[, INC_PER_PROP := 0][RENTA_ALQ2 > 0, INC_PER_PROP := RENTA_ALQ2 / NPROP_ALQ]

# Prepare data as survey object

dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL)

# Perform calculations to obtain sample statistics

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
caseros_total <- svyquantile(~NPROP_ALQ, subset(dt_sv, NPROP_ALQ > 0), quantiles = c(seq(.5, .95, by = .05), .99))$NPROP_ALQ[, 1] %>%
    print()
rent_prop <- svymean(~RENTA_ALQ2, subset(dt_sv, RENTA_ALQ2 > 0))[1] %>%
    round(3)
med_rent_prop <- svyquantile(~RENTA_ALQ2, subset(dt_sv, RENTA_ALQ2 > 0), quantiles = .5)$RENTA_ALQ2[, 1]
props_alq <- svymean(~NPROP_ALQ, subset(dt_sv, NPROP_ALQ > 0))[1]

# Prepare and export results

results <- cbind(prop_caseros[-1], conc_rentistas, conc_caseros, ave_income, ave_income_per_prop)
pob_inq <- data.table(TIPO_PROP = "no_caseros", N = prop_caseros$N[1], NPROP_ALQ = 0, RENTA_ALQ2 = 0, RENTA_ALQ2 = 0, INC_PER_PROP = 0)

results <- rbind(results, pob_inq)
colnames(results) <- c(
    "Nº propiedades alquiladas",
    "% total de hogares",
    "% total de viviendas alquiladas",
    "% total rentas del alquiler",
    "ingresos medios alquiler",
    "ingresos medios por inmueble"
)
print(results)
# fwrite(results, paste0("AEAT/out/segovia/segovia-", sel_year, "-IDENHOGreal_estate.csv"))

dt[, casero := ifelse(RENTA_ALQ2 > 0, 1, 0)]
dt_sv$variables[, "casero"] <- dt$casero
dt[, gran_tenedor := ifelse(RENTA_ALQ2 > 9, 1, 0)]
dt_sv$variables[, "gran_tenedor"] <- dt$gran_tenedor

svytotal(~NPROP_ALQ, dt_sv) %>% print()
svytotal(~casero, dt_sv) %>% print()
svytotal(~gran_tenedor, dt_sv) %>% print()
svytotal(~RENTA_ALQ2, dt_sv) %>% print()

svytotal(~as.factor(gran_tenedor), dt_sv) %>% prop.table()
