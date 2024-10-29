# clean enviroment and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")
pop_stats <- fread("AEAT/data/pop-stats.csv")

# define city subsample and variables to analyze
export <- "TRUE"
city <- "segovia"
represet <- "!is.na(FACTORCAL)"
sel_year <- 2021
ref_unit <- "IDENHOG"
calib_mode <- FALSE

# get a sample weighted for a given city
dt <- get_wave(
    city = city, # subregional unit
    sel_year = sel_year, # wave
    ref_unit = ref_unit, # reference PSU (either household or individual)
    represet = represet, # reference universe/population (whole pop. or tax payers)
    calibrated = calib_mode, # Weight calib. (TRUE, FALSE, TWO-STEPS) Requieres auxiliary total/mean data
) %>% subset(MUESTRA == pop_stats[muni == city & year == sel_year, index])

dt$FACTORCAL <- (21034 / sum(dt$FACTORCAL)) * dt$FACTORCAL
# define survey for the subsample of interest
dt_sv <- svydesign(
    ids = ~IDENHOG,
    data = dt,
    weights = dt$FACTORCAL
)


original <- fread("AEAT/data/tipohog-segovia-2021.csv")
estimated <- svytotal(~TIPOHOG, dt_sv, na.rm = TRUE) %>% as.numeric()

frequencies <- data.frame(TIPOHOG = original$Tipohog, Freq = original$Total)

# Combine the two vectors into a matrix
data_matrix <- rbind(original$Total, estimated)

# Plot the bars
barplot(data_matrix,
    beside = TRUE, col = c("blue", "red"),
    names.arg = paste("Category", seq_along(original)),
    main = "Overlay of original and estimated",
    xlab = "Categories",
    ylab = "Values",
    legend.text = c("original", "estimated")
)
