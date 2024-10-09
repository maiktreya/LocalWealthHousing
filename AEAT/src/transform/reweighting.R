# Functions needed to reweight subsamples from AEAT from levels below CCAA

# STEP 1: Iterative reweighting given known frequencies of sex and age groups

rake_data_multi <- function(dt = dt, sel_year = sel_year, city = city) {
    # function dependencies
    library(data.table, quietly = TRUE)
    library(survey, quietly = TRUE)

    # import external population values
    city_index <- fread("AEAT/data/pop-stats.csv")[muni == city & year == sel_year, index]
    tipohog_pop <- fread(paste0("AEAT/data/tipohog-", city, "-", sel_year, ".csv"), encoding = "UTF-8")[, .(Tipohog = as.factor(Tipohog), Total)]
    tramo_pop <- fread(paste0("AEAT/data/base_hogar/", city, sel_year, "_tramo.csv"), encoding = "UTF-8")[, .(Tramo = as.factor(Tramo), Total)]
    tipohog_pop <- setNames(tipohog_pop$Total, paste0("TIPOHOG", tipohog_pop$Tipohog))
    tramo_pop <- setNames(tramo_pop$Total, paste0("TRAMO", tramo_pop$Tramo))
    calibration_totals_vec <- c(tipohog_pop, tramo_pop)

    # coerce needed variables
    dt <- dt[!is.na(FACTORCAL)]
    dt[, TIPOHOG := as.factor(TIPOHOG)]
    dt[, TRAMO := as.factor(TRAMO)]

    # Prepare survey object
    dt_sv <- svydesign(
        ids = ~IDENHOG,
        strata = ~ CCAA + TIPOHOG + TRAMO,
        data = dt,
        weights = dt$FACTORCAL,
        nest = TRUE
    )
    pre_subsample <- subset(dt_sv, MUESTRA == city_index)
    limits <- c(min(weights(pre_subsample)), max(weights(pre_subsample)))

    # Apply calibration with the new named vector
    subsample <- calibrate(
        design = pre_subsample,
        formula = ~ -1 + TIPOHOG + TRAMO,
        population = calibration_totals_vec
    )
    return(dt)
}

rake_data <- function(dt = dt, sel_year = sel_year, city = city) {
    # function dependencies
    library(data.table, quietly = TRUE)
    library(survey, quietly = TRUE)

    # import external population values
    city_index <- fread("AEAT/data/pop-stats.csv")[muni == city & year == sel_year, index]
    tipohog_pop <- fread(paste0("AEAT/data/tipohog-", city, "-", sel_year, ".csv"), encoding = "UTF-8")[, .(Tipohog = as.factor(Tipohog), Total)]

    calibration_totals_vec <- setNames(tipohog_pop$Total, paste0("TIPOHOG", tipohog_pop$Tipohog))

    # coerce needed variables
    dt <- dt[!is.na(FACTORCAL)]
    dt[, TIPOHOG := as.factor(TIPOHOG)]

    # Prepare survey object
    dt_sv <- svydesign(
        ids = ~IDENHOG,
        strata = ~ CCAA + TIPOHOG + TRAMO,
        data = dt,
        weights = dt$FACTORCAL,
        nest = TRUE
    )
    pre_subsample <- subset(dt_sv, MUESTRA == city_index)
    limits <- c(min(weights(pre_subsample)), max(weights(pre_subsample)))

    # Apply calibration with the new named vector
    subsample <- calibrate(
        design = pre_subsample,
        formula = ~ -1 + TIPOHOG,
        population = calibration_totals_vec
    )


    # Update weights after calibration
    dt <- subsample$variables
    dt[, FACTORCAL := weights(subsample)]

    return(dt)
}
# STEP 2: Calibrate for mean income or other known population parameter

calibrate_data <- function(dt = dt, sel_year = sel_year, ref_unit = ref_unit, city = city) {
    # function dependencies
    library(data.table, quietly = TRUE)
    library(survey, quietly = TRUE)

    # population values and indexes
    pop_stats <- fread("AEAT/data/pop-stats.csv")
    city_index <- pop_stats[muni == city & year == sel_year, index]
    RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]
    RNpop <- pop_stats[muni == city & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]

    # Prepare survey object
    dt_sv <- svydesign(ids = ~IDENHOG, data = dt, weights = dt$FACTORCAL)
    pre_subsample <- subset(dt_sv,
     MUESTRA == city_index)
    calibration_target <- c(RENTAB = RBpop * sum(weights(pre_subsample)), RENTAD = RNpop * sum(weights(pre_subsample)))
    limits <- c(min(weights(pre_subsample)), max(weights(pre_subsample)))
    subsample <- calibrate(pre_subsample, ~ -1 + RENTAB + RENTAD, calibration_target, calfun = "raking")
    dt <- subsample$variables
    dt[, FACTORCAL := weights(subsample)]

    # return data with new weights
    return(dt)
}
