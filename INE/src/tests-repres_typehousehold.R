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
city <- "madrid"
represet <- "!is.na(FACTORCAL)"
sel_year <- 2016
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
    TIPOHOG == "1.1.1", 1,
    TIPOHOG == "1.1.2", 2,
    TIPOHOG %in% c("1.2", "2.1.1", "2.1.2", "2.2.1", "2.1.3"), 3,
    TIPOHOG %in% c("2.2.1", "2.2.2"), 4,
    TIPOHOG %in% c("2.3.1", "2.3.2"), 5
)][, TIPOHOG1 := as.factor(TIPOHOG1)]


dt_sv <- svydesign(ids = ~IDENHOG, data = dt, weights = dt$FACTORCAL) %>% subset(MUESTRA == pop_stats[muni == city & year == sel_year, index])

new_tipohog_names <- fread(paste0("AEAT/data/tipohog-segovia-", sel_year, "-reduced.csv"))[, .(index, Tipohog, Desc)]

new_tipohog_tot <- svytotal(~TIPOHOG1, dt_sv) %>%
    as.numeric() %>%
    print()

new_tipohog_freq <- svytotal(~TIPOHOG1, dt_sv) %>%
    prop.table() %>%
    as.numeric()

new_tipohog <- data.table(new_tipohog_names, Freq = new_tipohog_freq, Total = new_tipohog_tot)

fwrite(new_tipohog, paste0("AEAT/data/tipohog-", city, "-", sel_year, "-reduced.csv"))
