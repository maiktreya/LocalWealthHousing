# clean enviroment and import dependencies
rm(list = ls())
gc(full = TRUE, verbose = TRUE)
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")
pop_stats <- fread("AEAT/data/pop-stats.csv")
tipos_cat <- fread("AEAT/data/tipohog-madrid-2016.csv")[, .(Desc, Tipohog, index)]

# define city subsample and variables to analyze
export_object <- FALSE
city <- "segovia"
represet <- "!is.na(FACTORCAL)"
sel_year <- 2021
ref_unit <- "IDENHOG"
calib_mode <- FALSE
RNpop <- pop_stats[muni == city & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]
RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]

# get a sample weighted for a given city
dt <- get_wave(
    city = city, # subregional unit
    sel_year = sel_year, # wave
    ref_unit = ref_unit, # reference PSU (either household or individual)
    represet = represet, # reference universe/population (whole pop. or tax payers)
    calibrated = calib_mode, # Weight calib. (TRUE, FALSE, TWO-STEPS) Requieres auxiliary total/mean data
)
dt[, TIPOHOG1 := fcase(
    default = NA,
    TIPOHOG == 1, 1,
    TIPOHOG == 2, 2,
    TIPOHOG %in% c(3, 4, 5, 6), 3,
    TIPOHOG %in% c(7, 8), 4,
    TIPOHOG %in% c(9, 10), 5
)]


dt_sv <- svydesign(ids = ~IDENHOG, data = dt, weights = dt$FACTORCAL) %>% subset(MUESTRA == pop_stats[muni == city & year == sel_year, index])

svytotal(~TIPOHOG1, dt_sv) %>% data.table() %>% print()