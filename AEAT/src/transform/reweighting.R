# Functions needed to reweight subsamples from AEAT from levels below CCAA


# STEP 1: Iterative reweighting given known frequencies of sex and age groups

rake_data <- function(dt = dt, sel_year = sel_year, city = city) {
    # function dependencies
    library(data.table, quietly = TRUE)
    library(survey, quietly = TRUE)
    m_labels <- c("male_0-19", "male_20-39", "male_40-59", "male_60-79", "male_80-99+")
    f_labels <- c("female_0-19", "female_20-39", "female_40-59", "female_60-79", "female_80-99+")
    age_labels <- c("0-19", "20-39", "40-59", "60-79", "80-99+")
    city_index <- fread("AEAT/data/pop-stats.csv")[muni == city & year == sel_year, index]

    # reshape age categories
    m_vector <- fread(paste0("AEAT/data/", city, "-age-freq.csv"))[, .(sex_age, Freq = get(paste0("freqmale", sel_year)))]
    m_vector <- m_vector[, group := ceiling(.I / 4)][, .(Freq = sum(Freq)), by = group]
    m_vector <- cbind(sex_age = m_labels, m_vector)[, group := NULL]
    f_vector <- fread(paste0("AEAT/data/", city, "-age-freq.csv"))[, .(sex_age, Freq = get(paste0("freqfemale", sel_year)))]
    f_vector <- f_vector[, group := ceiling(.I / 4)][, .(Freq = sum(Freq)), by = group]
    f_vector <- cbind(sex_age = f_labels, f_vector)[, group := NULL]
    age_vector <- rbind(f_vector, m_vector)

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

    # Define raking margins
    margins <- list(~sex_age)

    # Population proportions for raking
    pop_totals <- list(age_vector)

    # Prepare survey object
    dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL)
    pre_subsample <- subset(dt_sv, MUESTRA == city_index)

    # Apply raking for sex and age cohorts
    subsample <- rake(
        design = pre_subsample,
        sample.margins = margins,
        population.margins = pop_totals
    )

    dt <- subsample$variables
    dt[, FACTORCAL := weights(subsample)]

    # return data with new weights
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

    # Prepare survey object
    dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL)
    pre_subsample <- subset(dt_sv, MUESTRA == city_index)

    # Calibrate for mean income
    calibration_target <- c(
        RENTAB = RBpop * sum(pre_subsample$variables[, FACTORCAL])
    )
    subsample <- calibrate(pre_subsample, ~ -1 + RENTAB, calibration_target)

    dt <- subsample$variables
    dt[, FACTORCAL := weights(subsample)]

    # return data with new weights
    return(dt)
}
