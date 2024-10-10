# R script for transforming base AEAT sample files from their tax record sample.
#
#' @description
#' This script processes AEAT sample files to generate summarized and cleaned data
#' for analysis. It allows selection of data from specified years (2016 or 2021) and
#' aggregates information based on either household or individual reference units.
#' The script performs data transformations, including handling missing values.
#' The final output is a tidy data table ready for further analysis.
#
#' @details
#' The following parameters can be adjusted:
#' - sel_year: The year to select data from (2016 or 2021). Default is 2016.
#' - ref_unit: Aggregation unit: "IDENHOG" (household) or "IDENPER" (individual).
#' - represet: Logical condition representing the population analyzed;
#'   for only declarants: 'TIPODEC %in% c("T1", "T21") & !is.na(FACTORCAL)'.
#'   for whole population: '!is.na(FACTORCAL)'.
#' - sel_cols: Chosen columns to coerce to numeric types.
#' - calibrated: Defines an intermediate calibration step
#'
#' Outputs a data.table with aggregated and processed information.

get_wave <- function(
    #' @param reference city to subsample. Default is NULL
    city = NULL,
    #' @param sel_year Year to select data from (2016 or 2019). Default is 2016. Number
    sel_year = 2016,
    #' @param ref_unit Aggregation unit: "IDENHOG" (household) or "IDENPER" (individual). String
    ref_unit = "IDENHOG",
    #' @param represet Represents the whole population analyzed. For only declarants:
    #' 'TIPODEC %in% c("T1", "T21") & !is.na(FACTORCAL)'.
    represet = "!is.na(FACTORCAL)",
    #' @param sel_cols Chosen columns to coerce to numeric types.
    sel_cols = c("RENTAD", "RENTAB", "RENTA_ALQ", "PATINMO", "REFCAT", "INCALQ", "PAR150i"),
    #' @param calibrated Set an intermediate step to calibrate for a subsample. Boolean. Default is false.
    calibrated = FALSE) {
    # Load the data.table library for efficient data manipulation.
    library(data.table, quietly = TRUE)
    source("AEAT/src/transform/reweighting.R")

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
        CCAA == "13" & PROV == "28", 6, # MadridCCCAA
        default = 0
    )]

    # Calculate rental income & id for rental properties
    dt[, RENTA_ALQ2 := fifelse(PAR150i > 0, INCALQ, 0)]
    dt[, ID_PROP := 0][REFCAT > 0, ID_PROP := 1]
    dt[, ID_PROP_ALQ := 0][PAR150i > 0, ID_PROP_ALQ := 1]

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
        MIEMBROS = uniqueN(IDENPER), # Number of unique family members
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

    # Calculate remaining income without rental rents
    dt[, RENTAD_NOAL := RENTAD - RENTA_ALQ2]

    # finally calibrate if needed
    if (calibrated) dt <- calibrate_data(dt, sel_year, ref_unit, city)

    # Return the final tidy data table
    return(dt)
}
