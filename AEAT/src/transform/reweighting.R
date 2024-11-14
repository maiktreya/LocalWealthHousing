# Post-stratification & calibration function for AEAT data

calibrate_data <- function(
    dt = NULL,
    sel_year = NULL,
    ref_unit = "IDENHOG",
    city = NULL,
    pop_stats_file = "AEAT/data/pop-stats.csv",
    file_suffix = "") {
    # Dependencies
    library(data.table, quietly = TRUE)
    library(survey, quietly = TRUE)
    library(magrittr, quietly = TRUE)

    # Import population values
    pop_stats <- fread(pop_stats_file)
    RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]
    RNpop <- pop_stats[muni == city & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]

    # Check population values are available
    if (is.na(RBpop) || is.na(RNpop)) stop("Population values for the specified year, unit, or city are missing.")

    # Import household type data
    if (file_suffix != "") file_suffix <- paste0(file_suffix, "-") 
    tipohog_pop <- paste0("AEAT/data/tipohog-", city, "-", sel_year, file_suffix, ".csv") %>% fread()
    tipohog_pop <- data.frame(TIPOHOG1 = tipohog_pop$Tipohog, Freq = tipohog_pop$Total)

    # Remove rows with missing FACTORDIS values
    dt <- dt[!is.na(FACTORDIS)]

    # Use base type of households if compacted categories are not needed
    if (file_suffix != "-reduced") dt[, TIPOHOG1 := TIPOHOG]

    # Define survey design
    sv_design_base <- svydesign(
        ids = ~IDENHOG,
        strata = ~ CCAA + TIPOHOG + TRAMO,
        data = dt,
        weights = dt$FACTORDIS,
        nest = TRUE
    ) %>% subset(MUESTRA == pop_stats[muni == city & year == sel_year, index])

    # Post-stratify by household type
    sv_design <- postStratify(
        design = sv_design_base,
        strata = ~TIPOHOG1,
        population = tipohog_pop
    )

    # Calibration vector for income totals
    calibration_totals_vec <- c(
        RENTAB = RBpop * sum(weights(sv_design))
    )

    # Set limits to get the same range for weights after calibration
    limits <- c(min(weights(sv_design_base)), max(weights(sv_design_base)))

    # Apply calibration
    calibrated_design <- calibrate(
        design = sv_design,
        formula = ~ -1 + RENTAB,
        population = calibration_totals_vec,
        bounds = limits,
        # bounds.const = TRUE,
        calfun = "linear",
        maxit = 20000
    )

    # Extract the data matrix
    dt <- calibrated_design$variables

    # Update weights
    dt[, FACTORCAL := weights(calibrated_design)]
    dt[, FACTORCAL := (sum(weights(sv_design)) / sum(FACTORCAL)) * FACTORCAL]

    return(dt)
}
