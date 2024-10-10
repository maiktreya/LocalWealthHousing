# Functions needed to reweight subsamples from AEAT from levels below CCAA

# STEP 1: Iterative reweighting given known frequencies of sex and age groups

calibrate_data <- function(dt = dt, sel_year = sel_year, city = city) {
    # function dependencies
    library(data.table, quietly = TRUE)
    library(survey, quietly = TRUE)

    # import external population values
    RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]
    RNpop <- pop_stats[muni == city & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]
    city_index <- fread("AEAT/data/pop-stats.csv")[muni == city & year == sel_year, index]
    tipohog_pop <- fread(paste0("AEAT/data/tipohog-", city, "-", sel_year, ".csv"), encoding = "UTF-8")[, .(Tipohog = as.factor(Tipohog), Total)]
    tramo_pop <- fread(paste0("AEAT/data/base_hogar/", city, sel_year, "_tramo.csv"), encoding = "UTF-8")[, .(Tramo = as.factor(Tramo), Total)]
    tipohog_pop <- setNames(tipohog_pop$Total, paste0("TIPOHOG", tipohog_pop$Tipohog))
    tramo_pop <- setNames(tramo_pop$Total, paste0("TRAMO", tramo_pop$Tramo))

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
    calibration_totals_vec <- c(tipohog_pop, RENTAB = RBpop * sum(weights(pre_subsample)), RENTAD = RNpop * sum(weights(pre_subsample)))

    # Apply calibration with the new named vector
    subsample <- calibrate(
        design = pre_subsample,
        formula = ~ -1 + TIPOHOG + RENTAB + RENTAD,
        population = calibration_totals_vec,
        calfun = "raking",
        bounds = limits,
        bounds.const = TRUE
    )

    dt <- subsample$variables
    dt[, FACTORCAL := weights(subsample)]
    return(dt)
}
