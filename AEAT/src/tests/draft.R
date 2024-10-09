# clean enviroment and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")
pop_stats <- fread("AEAT/data/pop-stats.csv")

# define city subsample and variables to analyze
export_object <- FALSE
city <- "madrid"
represet <- "!is.na(FACTORCAL)"
sel_year <- 2016
ref_unit <- "IDENHOG"
rake_mode <- TRUE
calib_mode <- FALSE
city_index <- pop_stats[muni == city & year == sel_year, index]
RNpop <- pop_stats[muni == city & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]
RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]
sel_cols <- c("RENTAD", "RENTAB", "RENTA_ALQ", "PATINMO", "REFCAT", "INCALQ", "PAR150i")


# Load the data.table library for efficient data manipulation.
library(data.table, quietly = TRUE)
source("AEAT/src/transform/reweighting.R")

# Load data from the specified year
dt <- fread(paste0("AEAT/data/IEF-", sel_year, "-new.gz"))

# Replace NA values with 0 in selected columns
setnafill(dt, type = "const", fill = 0, cols = sel_cols)

# Coerce TRAMO to numeric, treating "N" as 8
dt[TRAMO == "N", TRAMO := 8][, TRAMO := as.numeric(TRAMO)]

# Assign sample identifier (MUESTRA) based on geographical identifiers
dt[, MUESTRA := fcase(
    CCAA == "7" & PROV == "40" & MUNI == "194", 1, # Segovia
    CCAA == "7" & PROV == "40" & MUNI == "112", 2, # Lastrilla
    CCAA == "7" & PROV == "40" & MUNI == "906", 3, # San Cristobal
    CCAA == "7" & PROV == "40" & MUNI == "155", 4, # Palazuelos
    CCAA == "13" & PROV == "28" & MUNI == "79", 5, # Madrid
    CCAA == "13" & PROV == "28", 6, # MadridCCCAA
    default = 0
)]

# Calculate rental income
dt[, RENTA_ALQ2 := fifelse(PAR150i > 0, INCALQ, 0)]

# STEP 1: Summarize information about real estate properties
dt <- dt[, .(
    MIEMBROS = uniqueN(IDENPER), # Number of unique family members
    NPROP_ALQ = uniqueN(REFCAT), # Number of unique rental properties
    IDENHOG = mean(IDENHOG), # household identifier
    TIPOHOG = first(TIPOHOG), # household type
    SEXO = mean(SEXO), # sex (1 = Male, 2 = Female)
    AGE = (sel_year) - mean(ANONAC), # Calculate average age
    RENTAB = mean(RENTAB), # rental income
    RENTAD = mean(RENTAD), # declared income
    TRAMO = mean(TRAMO), # TRAMO
    RENTA_ALQ = mean(RENTA_ALQ), # rental income
    RENTA_ALQ2 = mean(RENTA_ALQ2), # calculated rental income
    PAR150 = sum(PAR150i), # Total number of properties owned
    PATINMO = mean(PATINMO), # property value
    FACTORCAL = mean(FACTORCAL), # calculation factor
    CCAA = mean(CCAA), # Autonomous Community
    PROV = mean(PROV), # Province
    MUNI = mean(MUNI), # Municipality
    MUESTRA = mean(MUESTRA) # City identifiers (CCAA+PROV+MUNI)
), by = .(IDENPER)]


# STEP 2: Filter and tidy data for the specified reference unit
dt <- dt[eval(parse(text = represet)), .(
    MIEMBROS = mean(MIEMBROS),
    NPROP_ALQ = mean(NPROP_ALQ),
    IDENHOG = mean(IDENHOG),
    TIPOHOG = first(TIPOHOG), # household type
    SEXO = mean(SEXO),
    AGE = mean(AGE),
    RENTAB = sum(RENTAB),
    RENTAD = sum(RENTAD),
    TRAMO = mean(TRAMO),
    RENTA_ALQ = sum(RENTA_ALQ),
    RENTA_ALQ2 = sum(RENTA_ALQ2),
    PAR150 = sum(PAR150),
    PATINMO = sum(PATINMO),
    FACTORCAL = mean(FACTORCAL),
    CCAA = mean(CCAA),
    PROV = mean(PROV),
    MUNI = mean(MUNI),
    MUESTRA = mean(MUESTRA)
), by = .(reference = get(ref_unit))]


# import external population values
city_index <- fread("AEAT/data/pop-stats.csv")[muni == city & year == sel_year, index]
tipohog_pop <- fread(paste0("AEAT/data/tipohog-", city, "-", sel_year, ".csv"), encoding = "UTF-8")[, .(Tipohog=as.factor(Tipohog), Total)]

# coerce needed variables 
dt <- dt[!is.na(FACTORCAL)]
dt[, gender := fifelse(SEXO == 1, "male", "female")]
dt[, TIPOHOG := as.factor(TIPOHOG)]
calibration_totals_vec <- setNames(tipohog_pop$Total, tipohog_pop$Tipohog)

# Prepare survey object
dt_sv <- svydesign(ids = ~IDENHOG, data = dt, weights = dt$FACTORCAL)
pre_subsample <- subset(dt_sv, MUESTRA == city_index)
calibration_totals_vec <- setNames(age_vector$Freq, paste0("sex_age", as.character(age_vector$sex_age)))
limits <- c(min(weights(pre_subsample)), max(weights(pre_subsample)))

# Apply calibration with the new named vector
subsample <- calibrate(
    design = pre_subsample,
    formula = ~ -1 + TIPOHOG,
    population = calibration_totals_vec,
    calfun = "raking"
)

# Update weights after calibration
dt <- subsample$variables
dt[, FACTORCAL := weights(subsample)]

