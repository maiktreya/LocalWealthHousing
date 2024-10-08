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


##########################################

    m_labels <- c("male_0-19", "male_20-39", "male_40-59", "male_60-79", "male_80-99+")
    f_labels <- c("female_0-19", "female_20-39", "female_40-59", "female_60-79", "female_80-99+")
    age_labels <- c("0-19", "20-39", "40-59", "60-79", "80-99+")
    city_index <- fread("AEAT/data/pop-stats.csv")[muni == city & year == sel_year, index]
    total_pop <- fread(paste0("AEAT/data/base/", city, "-sex.csv"))[year == sel_year, total]

    # reshape age categories
    m_vector <- fread(paste0("AEAT/data/", city, "-age-freq.csv"))[, .(age_group, Freq = get(paste0("freqmale", sel_year)))]
    m_vector <- m_vector[, group := ceiling(.I / 4)][, .(Freq = sum(Freq)), by = group][, Freq := Freq * total_pop]
    m_vector <- cbind(sex_age = m_labels, m_vector)[, group := NULL]
    f_vector <- fread(paste0("AEAT/data/", city, "-age-freq.csv"))[, .(age_group, Freq = get(paste0("freqfemale", sel_year)))]
    f_vector <- f_vector[, group := ceiling(.I / 4)][, .(Freq = sum(Freq)), by = group][, Freq := Freq * total_pop]
    f_vector <- cbind(sex_age = f_labels, f_vector)[, group := NULL]
    age_vector <- rbind(f_vector, m_vector)
    age_vector$sex_age <- factor(age_vector$sex_age, levels = unique(age_vector$sex_age))
    age_vector <- age_vector[order(age_vector$sex_age), ]

    # Create a new age_group based on broader 20-year intervals
    dt[, age_group := cut(
        AGE,
        breaks = c(0, 20, 40, 60, 80, Inf), # Defining 20-year groups
        right = FALSE,
        labels = age_labels,
        include.lowest = TRUE
    )]
    dt <- dt[!is.na(age_group)]
    dt <- dt[!is.na(FACTORCAL)]
    dt[, gender := fifelse(SEXO == 1, "male", "female")]
    dt[, sex_age := interaction(gender, age_group, sep = "_")]

    # Prepare survey object
    dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL)
    pre_subsample <- subset(dt_sv, MUESTRA == city_index)
    calibration_totals_vec <- setNames(age_vector$Freq, paste0("sex_age", as.character(age_vector$sex_age)))
    limits <- c(min(weights(pre_subsample)), max(weights(pre_subsample)))

    # Apply calibration with the new named vector
    subsample <- calibrate(
        design = pre_subsample,
        formula = ~ -1 + sex_age,
        population = calibration_totals_vec,
        calfun = "raking",
        trim = c(0.1, 2),
        epsilon = 1e-5,
        maxit = 1000
    )

        # Update weights after calibration
    dt <- subsample$variables
    dt[, FACTORCAL := weights(subsample)]