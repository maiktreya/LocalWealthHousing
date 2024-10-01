# Import needed data objects

calibrate <- function(dt) {
    dt <- copy(dt)
    city <- "madrid"
    age_labels <- c("0-19", "20-39", "40-59", "60-79", "80-99", "100+")

    # population values
    pop_stats <- fread("AEAT/data/pop-stats.csv")
    RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower("IDENPER")))]

    # reshape sex categories
    sex_vector <- fread("AEAT/data/madrid-sex-freq.csv")[, .(gender, Freq = get(paste0("freq", sel_year)))]

    # reshape age categories
    age_vector <- fread("AEAT/data/madrid-age-freq.csv")[, .(age_group, Freq = get(paste0("freq", sel_year)))]
    age_vector <- age_vector[, group := ceiling(.I / 4)][, .(Freq = sum(Freq)), by = group]
    age_vector <- cbind(age_group = age_labels, age_vector)[, group := NULL]

    # Create a new age_group based on broader 20-year intervals, with the last one open-ended
    dt[, age_group := cut(
        AGE,
        breaks = c(0, 20, 40, 60, 80, 100, Inf), # Defining 20-year groups with the last being open-ended
        right = FALSE,
        labels = age_labels,
        include.lowest = TRUE
    )]
    dt <- dt[!is.na(age_group)]
    dt <- dt[!is.na(FACTORCAL)]
    dt[, gender := "female"][SEXO == 1, gender := "male"]
    # Define new categorical variables based on sample identifiers
    dt[, CIUDAD := fcase(
        MUESTRA == 1, "segovia",
        MUESTRA == 2, "lastrilla",
        MUESTRA == 3, "sancristobal",
        MUESTRA == 4, "palazuelos",
        MUESTRA == 5, "madrid",
        MUESTRA == 6, "madridCCAA",
        default = NA_character_
    )]
    # Define raking margins
    margins <- list(~gender, ~age_group)

    # Population proportions for raking
    pop_totals <- list(sex_vector, age_vector)

    # Prepare survey object from dt and set income cuts for quantiles dynamically
    dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL) # muestra con coeficientes de elevación
    pre_subsample <- subset(dt_sv, CIUDAD == city)

    # STEP 1: Calibrate for mean income
    calibration_target <- c(
        RENTAB = RBpop * sum(pre_subsample$variables[, FACTORCAL])
    )
    cal_subsample <- calibrate(pre_subsample, ~ -1 + RENTAB, calibration_target)

    # STEP 2: Apply raking for sex and age cohorts
    subsample <- rake(
        design = cal_subsample,
        sample.margins = margins,
        population.margins = pop_totals
    )

    dt <- subsample$variables
    dt[, FACTORCAL := weights(subsample)]

    return(dt)
}
