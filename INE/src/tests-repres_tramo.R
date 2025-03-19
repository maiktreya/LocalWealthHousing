# clean enviroment and import dependencies
rm(list = ls())
gc(full = TRUE, verbose = TRUE)
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")
pop_stats <- fread("AEAT/data/pop-stats.csv")
tipos_cat <- fread("AEAT/data/tramos-segovia-2016.csv")[, .(Tramo, index)]

# define city subsample and variables to analyze
export_object <- FALSE
city <- "segovia"
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
dt_sv <- svydesign(ids = ~IDENHOG, data = dt, weights = dt$FACTORCAL) %>% subset(MUESTRA == pop_stats[muni == city & year == sel_year, index])

# Calculate proportion of households by type
prop_tramos <- svytotal(~TRAMO, dt_sv) %>% data.table()

# Calculate frequencies and total
prop_tramos <- data.table(
    FREQ = prop.table(prop_tramos)[, 1],
    TOTAL = prop_tramos
)
prop_tramos <- cbind(tipos_cat, prop_tramos)
colnames(prop_tramos) <- c("Tramo", "index", "Freq.", "Total")
prop_tramos2 <- fread("AEAT/data/tramos-segovia-2016.csv")

final_table <- data.table(as.numeric(prop_tramos$Total), as.numeric(prop_tramos2$Total))
print(final_table)
chisq.test(final_table$V1, final_table$V2) %>% print()
chisq.test(final_table) %>% print()
