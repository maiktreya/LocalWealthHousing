# clean enviroment and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")
pop_stats <- fread("AEAT/data/pop-stats.csv")

# define city subsample and variables to analyze
export <- "TRUE"
city <- ""
represet <- "!is.na(FACTORCAL)"
sel_year <- 2016
ref_unit <- "IDENHOG"
calibrated <- FALSE

# get a sample weighted for a given city
dt <- get_wave(
    city = city, # subregional unit
    sel_year = sel_year, # wave
    ref_unit = ref_unit, # reference PSU (either household or individual)
    represet = represet, # reference universe/population (whole pop. or tax payers)
    calibrated = calibrated, # Weight calib. (TRUE/FALS)E Requieres auxiliary  data
)

# Define weights and create survey object
dt_sv <- svydesign(
    ~1,
    data = dt,
    weights = dt$FACTORCAL
) %>% subset(., pop_stats[muni == city & year == sel_year, index]) # ensure subsample of interest is selected in case calibration is not applied

# Calculate proportion of households by type
prop_tramo <- svytotal(~TRAMO, dt_sv) %>% data.table()

# Calculate frequencies and total
prop_tramo <- data.table(
    FREQ = prop.table(prop_tramo)[, 1],
    TOTAL = prop_tramo
)
prop_tramo[, index := .I]
colnames(prop_tramo) <- c("Freq.", "Total", "index")
prop_tramo2 <- fread(paste0("AEAT/data/tramos-segovia-", sel_year, ".csv"))
