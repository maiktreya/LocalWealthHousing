# clean enviroment and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/reweighting.R")
pop_stats <- fread("AEAT/data/pop-stats.csv")

# define city subsample and variables to analyze
export_object <- FALSE
city <- "madrid"
represet <- "!is.na(FACTORCAL)"
sel_year <- 2021
ref_unit <- "IDENHOG"
calib_mode <- TRUE
sel_cols <- c("RENTAD", "RENTAB", "RENTA_ALQ", "PATINMO", "REFCAT", "INCALQ", "PAR150i")
city_index <- pop_stats[muni == city & year == sel_year, index]
RNpop <- pop_stats[muni == city & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]
RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]

# Load data from the specified year
dt <- fread(paste0("AEAT/data/IEF-", sel_year, "-new.gz"))

# Replace NA values with 0 in selected columns
setnafill(dt, type = "const", fill = 0, cols = sel_cols)

# Coerce TRAMO to numeric, treating "N" as 8
dt[TRAMO == "N", TRAMO := -1][, TRAMO := as.numeric(TRAMO) + 1]

# Assign sample identifier (MUESTRA) based on geographical identifiers
dt[, MUESTRA := fcase(
    CCAA == "7" & PROV == "40" & MUNI == "194", 1, # Segovia
    CCAA == "7" & PROV == "40" & MUNI == "112", 2, # Lastrilla
    CCAA == "7" & PROV == "40" & MUNI == "906", 3, # San Cristobal
    CCAA == "7" & PROV == "40" & MUNI == "155", 4, # Palazuelos
    CCAA == "13" & PROV == "28" & MUNI == "79", 5, # Madrid
    CCAA == "13" & PROV == "28", 6, # MadridCCAA
    default = 0
)]

# Calculate rental income & id for rental properties
dt[, RENTA_ALQ2 := fifelse(PAR150i > 0, INCALQ, 0)]
dt[, ID_PROP := fifelse(RENTA_ALQ2 > 0, 1, 0)]
dt[, ID_PROP_ALQ := fifelse(PAR150i > 0, 1, 0)]


# STEP 1: Summarize information about real estate properties
dt <- dt[, .(
    NPROP = sum(ID_PROP), # Number of real estate properties
    NPROP_ALQ = sum(ID_PROP_ALQ), # Number of urban real estate properties generating rental income
    IDENHOG = mean(IDENHOG), # household identifier
    TIPOHOG = first(TIPOHOG), # type of household (10 categories)
    SEXO = mean(SEXO), # sex (1 = Male, 2 = Female)
    AGE = (sel_year) - mean(ANONAC), # Calculate average age
    RENTAB = mean(RENTAB), # rental income
    RENTAD = mean(RENTAD), # declared income
    TRAMO = mean(TRAMO), # TRAMO (income quantiles, 8 categories + 1 for missing)
    RENTA_ALQ = mean(RENTA_ALQ), # rental income
    RENTA_ALQ2 = sum(RENTA_ALQ2), # calculated rental income
    PAR150 = sum(PAR150i), # Total number of properties owned
    PATINMO = mean(PATINMO), # property value
    FACTORCAL = mean(FACTORCAL), # calculation factor
    FACTORDIS = mean(FACTORDIS), # calculation factor
    CCAA = mean(CCAA), # Autonomous Community
    PROV = mean(PROV), # Province
    MUNI = mean(MUNI), # Municipality
    MUESTRA = mean(MUESTRA) # City identifiers (CCAA+PROV+MUNI)
), by = .(IDENPER)]

# STEP 2: Before grouping into households, we set dummys for underage and retired people
dt[, RETIRED := 0][AGE > 65, RETIRED := 1]
dt[, UNDERAGE := 0][AGE < 18, UNDERAGE := 1]

# STEP 3: Filter and tidy data for the specified reference unit
dt <- dt[eval(parse(text = represet)), .(
    MIEMBROS = uniqueN(IDENPER), # Number of unique family members
    UNDERAGE = sum(UNDERAGE),
    RETIRED = sum(RETIRED),
    NPROP = sum(NPROP),
    NPROP_ALQ = sum(NPROP_ALQ),
    IDENHOG = mean(IDENHOG),
    TIPOHOG = first(TIPOHOG),
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
    FACTORDIS = mean(FACTORDIS), # calculation factor
    CCAA = mean(CCAA),
    PROV = mean(PROV),
    MUNI = mean(MUNI),
    MUESTRA = mean(MUESTRA)
), by = .(reference = get(ref_unit))]


# Rename column based on reference unit
if (ref_unit == "IDENHOG") {
    dt[, reference := NULL] # Remove reference column if using IDENHOG
} else {
    setnames(dt, "reference", as.character(ref_unit)) # Rename reference column
}

# Define ownership status variables
dt[, TENENCIA := fifelse(PAR150 > 0, "CASERO", fifelse(PATINMO > 0, "PROPIETARIO", "INQUILINA"))]
dt[, CASERO := factor(fifelse(PAR150 > 0, 1, 0))] # 1 if "CASERO", else 0
dt[, PROPIETARIO := factor(fifelse(PATINMO > 0 & CASERO == 0, 1, 0))] # 1 if "PROPIETARIO", else 0
dt[, INQUILINO := factor(fifelse(PROPIETARIO == 1 | CASERO == 1, 0, 1))] # 1 if "INQUILINO", else 0
dt[, TRAMO := as.factor(TRAMO)]

# Calculate remaining income without rental rents
dt[, RENTAD_NOAL := RENTAD - RENTA_ALQ2]

# import external population values
pop_stats <- fread("AEAT/data/pop-stats.csv")
RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]
RNpop <- pop_stats[muni == city & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]
city_index <- pop_stats[muni == city & year == sel_year, index]
tipohog_pop <- fread(paste0("AEAT/data/tipohog-", city, "-", sel_year, ".csv"), encoding = "UTF-8")[, .(Tipohog = as.factor(Tipohog), Total)]
tipohog_pop <- setNames(tipohog_pop$Total, paste0("TIPOHOG", tipohog_pop$Tipohog))
tipohog_red <- fread(paste0("AEAT/data/tipohog-", city, "-", sel_year, "-reduced.csv"), encoding = "UTF-8")[, .(Tipohog = as.factor(Tipohog), Total)]
tipohog_red <- setNames(tipohog_red$Total, paste0("TIPOHOG1", tipohog_red$Tipohog))
tramo_pop <- fread(paste0("AEAT/data/tramos-", city, "-", sel_year, ".csv"), encoding = "UTF-8")[, .(Tramo = as.factor(Tramo), Total)]
tramo_pop <- setNames(tramo_pop$Total, paste0("TRAMO", tramo_pop$Tramo))

# coerce needed variables
dt <- dt[!is.na(FACTORDIS)]
dt[, TIPOHOG := as.factor(TIPOHOG)]
dt[, TIPOHOG1 := fcase(
    TIPOHOG == "1.1.1", 1,
    TIPOHOG == "1.1.2", 2,
    TIPOHOG %in% c("1.2", "2.1.1", "2.1.2", "2.1.3"), 3,
    TIPOHOG %in% c("2.2.1", "2.2.2"), 4,
    TIPOHOG %in% c("2.3.1", "2.3.2"), 5,
    default = NA
)][, TIPOHOG1 := as.factor(TIPOHOG1)]

# Prepare survey object
dt_sv <- svydesign(
    ids = ~IDENHOG, # Household identifier for base PSU
    strata = ~ CCAA + TIPOHOG + TRAMO, # Region, household type, and income quantile
    data = dt, # already prepared matrix with individual variables of interest
    weights = dt$FACTORDIS, # original sampling weights (rep. for CCAA level)
    nest = TRUE # Households are nested within IDENPER and multiple REFCAT
)

# Subset for the geo-unit of interest
pre_subsample <- subset(dt_sv, MUESTRA == city_index)

# Set limits to get the same range for weights after calibration
limits <- c(min(weights(pre_subsample)), max(weights(pre_subsample)))

# set a named vector with the population values of reference for each variable
calibration_totals_vec <- c(
    tipohog_red
)

# Apply calibration with the new named vector
subsample <- calibrate(
    design = pre_subsample,
    formula = ~ -1 + TIPOHOG1,
    population = calibration_totals_vec,
    calfun = "linear",
    bounds = limits,
    bounds.const = TRUE,
    maxit = 3000,
    verbose = TRUE
)

# Extract dataframe of variables and weights from the survey object
dt <- subsample$variables

# Overwrite the column storing original weights with the ones obtained after calibraition
dt[, FACTORCAL := weights(subsample)]
