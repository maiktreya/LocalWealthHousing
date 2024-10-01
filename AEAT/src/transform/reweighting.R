# Functions needed to reweight subsamples from AEAT from levels below CCAA


# STEP 1: Iterative reweighting given known frequencies of sex and age groups

rake_data <- function(dt, sel_year, city = "madrid") {
    age_labels <- c("0-19", "20-39", "40-59", "60-79", "80-99", "100+")

    # reshape sex categories
    sex_vector <- fread("AEAT/data/madrid-sex-freq.csv")[, .(gender, Freq = get(paste0("freq", sel_year)))]

    # reshape age categories
    age_vector <- fread("AEAT/data/madrid-age-freq.csv")[, .(age_group, Freq = get(paste0("freq", sel_year)))]
    age_vector <- age_vector[, group := ceiling(.I / 4)][, .(Freq = sum(Freq)), by = group]
    age_vector <- cbind(age_group = age_labels, age_vector)[, group := NULL]

    # Create a new age_group based on broader 20-year intervals
    dt[, age_group := cut(
        AGE,
        breaks = c(0, 20, 40, 60, 80, 100, Inf), # Defining 20-year groups
        right = FALSE,
        labels = age_labels,
        include.lowest = TRUE
    )]
    dt <- dt[!is.na(age_group)]
    dt <- dt[!is.na(FACTORCAL)]
    dt[, gender := fifelse(SEXO == 1, "male", "female")]

    # Define raking margins
    margins <- list(~age_group, ~gender)

    # Population proportions for raking
    pop_totals <- list(age_vector, sex_vector)

    # Prepare survey object
    dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL)
    pre_subsample <- subset(dt_sv, MUESTRA == 5)

    # STEP 2: Apply raking for sex and age cohorts
    subsample <- rake(
        design = pre_subsample,
        sample.margins = margins,
        population.margins = pop_totals
    )

    dt <- subsample$variables
    dt[, FACTORCAL := weights(subsample)]

    return(dt)
}


# STEP 2: Calibrate for mean income or other known population parameter

calibrate_data <- function(dt, sel_year, ref_unit, city = "madrid") {
    # population values
    pop_stats <- fread("AEAT/data/pop-stats.csv")
    RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]

    # Prepare survey object
    dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL)
    pre_subsample <- subset(dt_sv, MUESTRA == 5)

    # STEP 1: Calibrate for mean income
    calibration_target <- c(
        RENTAB = RBpop * sum(pre_subsample$variables[, FACTORCAL])
    )
    subsample <- calibrate(pre_subsample, ~ -1 + RENTAB, calibration_target)

    dt <- subsample$variables
    dt[, FACTORCAL := weights(subsample)]

    return(dt)
}
