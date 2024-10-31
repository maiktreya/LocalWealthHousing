# clean enviroment and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")
pop_stats <- fread("AEAT/data/pop-stats.csv")

# define city subsample and variables to analyze
city <- "segovia"
represet <- "!is.na(FACTORCAL)"
sel_year <- 2021
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
    NPROP_ALQ == 1, "1",
    NPROP_ALQ == 2, "2",
    NPROP_ALQ == 3, "3",
    NPROP_ALQ == 4, "4",
    NPROP_ALQ > 4, "5+",
    default = "0"
)]
dt[, INC_PER_PROP := 0][RENTA_ALQ2 > 0, INC_PER_PROP := RENTA_ALQ2 / NPROP_ALQ]
dt[, NACIO := as.factor(NACIO)]
dt[, MIGR := 0][NACIO == 108, MIGR := 1][, MIGR := as.factor(MIGR)]
# Prepare data as survey object

dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL)

tipo_prop <- svyby(~TIPO_PROP, ~MIGR, dt_sv, svymean)[2:3] %>%
    round(2) %>%
    print()

tenencia_migr <- svyby(~TENENCIA, ~MIGR, dt_sv, svymean)[2:3] %>%
    round(2) %>%
    print()

prop_migr <- svytotal(~MIGR, dt_sv) %>%
    prop.table() %>%
    round(2) %>%
    print()
