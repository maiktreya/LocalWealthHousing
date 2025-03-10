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

    # coerce needed variables
    dt <- dt[!is.na(FACTORCAL)]
    dt[, TIPOHOG := as.factor(TIPOHOG)]

    # Prepare survey object
    dt_sv <- svydesign(
        ids = ~IDENHOG, # Household identifier for base PSU
        strata = ~ CCAA + TIPOHOG + TRAMO, # Region, household type, and income quantile
        data = dt, # already prepared matrix with individual variables of interest
        weights = dt$FACTORCAL, # original sampling weights (rep. for CCAA level)
        nest = TRUE # Households are nested within IDENPER and multiple REFCAT
    )

    # Subset for the geo-unit of interest
    pre_subsample <- subset(dt_sv, MUESTRA == city_index)

    # Set limits to get the same range for weights after calibration
    limits <- c(min(weights(pre_subsample)), max(weights(pre_subsample)))

    # set a named vector with the population values of reference for each variable
    calibration_totals_vec <- c(
        tipohog_pop,
        RENTAB = RBpop * sum(weights(pre_subsample))
    )
    # Apply calibration with the new named vector
    subsample <- calibrate(
        design = pre_subsample,
        formula = ~ -1 + TIPOHOG + RENTAB,
        population = calibration_totals_vec,
        calfun = "raking",
        bounds = limits,
        bounds.const = TRUE,
        maxit = 2000
    )

    # Extract dataframe of variables and weights from the survey object
    dt <- subsample$variables

    # Overwrite the column storing original weights with the ones obtained after calibraition
    dt[, FACTORCAL := weights(subsample)]

    # Return the survey dataframe including updated weights
    return(dt)
}
