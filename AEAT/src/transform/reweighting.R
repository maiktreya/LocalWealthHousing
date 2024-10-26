# Functions needed to reweight subsamples from AEAT from levels below CCAA

# STEP 1: Iterative reweighting given known frequencies of sex and age groups

calibrate_data <- function(dt = dt, sel_year = sel_year, ref_unit = ref_unit, city = city) {
    # function dependencies
    library(data.table, quietly = TRUE)
    library(survey, quietly = TRUE)

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
        default = NA,
        TIPOHOG == 1, 1,
        TIPOHOG == 2, 2,
        TIPOHOG %in% c(3, 4, 5, 6), 3,
        TIPOHOG %in% c(7, 8), 4,
        TIPOHOG %in% c(9, 10), 5
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
        # epsilon = 0.1,
        verbose = TRUE
    )

    # Extract dataframe of variables and weights from the survey object
    dt <- subsample$variables

    # Overwrite the column storing original weights with the ones obtained after calibraition
    dt[, FACTORCAL := weights(subsample)]

    # Return the survey dataframe including updated weights
    return(dt)
}
