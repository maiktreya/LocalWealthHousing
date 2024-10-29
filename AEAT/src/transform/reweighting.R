# Functions needed to reweight subsamples from AEAT from levels below CCAA

calibrate_data <- function(dt = dt, sel_year = sel_year, ref_unit = ref_unit, city = city) {
    # function dependencies
    library(data.table, quietly = TRUE)
    library(survey, quietly = TRUE)

    # import external population values
    pop_stats <- fread("AEAT/data/pop-stats.csv")
    RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]
    RNpop <- pop_stats[muni == city & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]
    tipohog_pop <- fread("AEAT/data/tipohog-segovia-2021.csv")
    tipohog_pop <- data.frame(TIPOHOG = tipohog_pop$Tipohog, Freq = tipohog_pop$Total)
    tramo_pop <- fread(paste0("AEAT/data/tramos-", city, "-", sel_year, ".csv"), encoding = "UTF-8")[, .(Tramo = as.factor(Tramo), Total)]
    tramo_pop <- setNames(tramo_pop$Total, paste0("TRAMO", tramo_pop$Tramo))

    # coerce needed variables
    dt <- dt[!is.na(FACTORDIS)]
    dt[, TIPOHOG := as.factor(TIPOHOG)]

    # Prepare survey object
    dt_sv <- svydesign(
        ids = ~IDENHOG, # Household identifier for base PSU
        strata = ~ CCAA + TIPOHOG + TRAMO, # Region, household type, and income quantile
        data = dt, # already prepared matrix with individual variables of interest
        weights = dt$FACTORDIS, # original sampling weights (rep. for CCAA level)
        nest = TRUE # Households are nested within IDENPER and multiple REFCAT
    ) %>% subset(MUESTRA == pop_stats[muni == city & year == sel_year, index])

    dt_sv <- postStratify(
        design = dt_sv,
        strata = ~TIPOHOG,
        population = tipohog_pop
    )

    # set a named vector with the population values of reference for each variable
    calibration_totals_vec <- c(
        RENTAB = RBpop * sum(weights(dt_sv)),
        RENTAD = RNpop * sum(weights(dt_sv))
    )

    # Apply calibration with the new named vector
    subsample <- calibrate(
        design = dt_sv,
        formula = ~ -1 + RENTAB + RENTAD,
        population = calibration_totals_vec,
        calfun = "raking",
        maxit = 2000
    )

    # Extract dataframe of variables and weights from the survey object
    dt <- subsample$variables

    # Overwrite the column storing original weights with the ones obtained after calibraition
    dt[, FACTORCAL := weights(subsample)]

    # Return the survey dataframe including updated weights
    return(dt)
}
