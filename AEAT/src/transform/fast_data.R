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
)  %>% subset(dt, MUESTRA == 6) # ensure subsample of interest is selected in case calibration is not applied

# export reduced recalibrated matrix
if (export == TRUE) fwrite(dt, paste0("AEAT/data/", city, ref_unit, sel_year, ".gz"))
