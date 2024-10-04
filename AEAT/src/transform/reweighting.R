# Functions needed to reweight subsamples from AEAT from levels below CCAA


# STEP 1: Iterative reweighting given known frequencies of sex and age groups

rake_data_interaction <- function(dt = dt, sel_year = sel_year, city = city) {
    # function dependencies
    library(data.table, quietly = TRUE)
    library(survey, quietly = TRUE)
    m_labels <- c("male_0-19", "male_20-39", "male_40-59", "male_60-79", "male_80-99+")
    f_labels <- c("female_0-19", "female_20-39", "female_40-59", "female_60-79", "female_80-99+")
    age_labels <- c("0-19", "20-39", "40-59", "60-79", "80-99+")
    city_index <- fread("AEAT/data/pop-stats.csv")[muni == city & year == sel_year, index]
    total_pop <- fread(paste0("AEAT/data/base/", city, "-sex.csv"))[year == sel_year, total]

    # reshape age categories
    m_vector <- fread(paste0("AEAT/data/", city, "-age-freq.csv"))[, .(age_group, Freq = get(paste0("freqmale", sel_year)))]
    m_vector <- m_vector[, group := ceiling(.I / 4)][, .(Freq = sum(Freq)), by = group][, Freq := Freq * total_pop]
    m_vector <- cbind(sex_age = m_labels, m_vector)[, group := NULL]
    f_vector <- fread(paste0("AEAT/data/", city, "-age-freq.csv"))[, .(age_group, Freq = get(paste0("freqfemale", sel_year)))]
    f_vector <- f_vector[, group := ceiling(.I / 4)][, .(Freq = sum(Freq)), by = group][, Freq := Freq * total_pop]
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
        population.margins = pop_totals,
        control = list(verbose = TRUE)
    )

    dt <- subsample$variables
    dt[, FACTORCAL := weights(subsample)]

    # return data with new weights
    return(dt)
}

rake_data <- function(dt = dt, sel_year = sel_year, city = city) {
    # function dependencies
    library(data.table, quietly = TRUE)
    library(survey, quietly = TRUE)

    # labels and indexes
    age_labels <- c("0-24", "25-49", "50-74", "+75")
    pop_stats <- fread("AEAT/data/pop-stats.csv")
    city_index <- pop_stats[muni == city & year == sel_year, index] %>% as.numeric()
    total_pop <- fread(paste0("AEAT/data/base/", city, "-sex.csv"))[year == sel_year, total]

    # reshape sex categories
    sex_vector <- fread(paste0("AEAT/data/", city, "-sex-freq.csv"))[, .(gender, Freq = get(paste0("freq", sel_year)))]

    # reshape age categories
    age_vector <- fread(paste0("AEAT/data/", city, "-age-freq.csv"))[, .(age_group, Freq = get(paste0("freq", sel_year)))]
    age_vector <- age_vector[, group := ceiling(.I / 5)][, .(Freq = sum(Freq)), by = group][, Freq := Freq * total_pop]
    age_vector <- cbind(age_group = age_labels, age_vector)[, group := NULL]

    # Create a new age_group based on broader 20-year intervals
    dt[, age_group := cut(
        AGE,
        breaks = c(0, 25, 50, 75, Inf), # Defining 20-year groups
        right = FALSE,
        labels = age_labels,
        include.lowest = TRUE
    )]
    dt <- dt[!is.na(age_group)]
    dt <- dt[!is.na(FACTORCAL)]
    dt[, gender := fifelse(SEXO == 1, "male", "female")]

    # Define raking margins
    margins <- list(
        ~gender,
        ~age_group
    )

    # Population proportions for raking
    pop_totals <- list(
        sex_vector,
        age_vector
    )

    # Prepare survey object
    dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL)
    pre_subsample <- subset(dt_sv, MUESTRA == city_index)

    # Apply raking for sex and age cohorts
    subsample <- rake(
        design = pre_subsample,
        sample.margins = margins,
        population.margins = pop_totals,
        control = list(verbose = TRUE)
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

calibrate_data_full <- function(dt = dt, sel_year = sel_year, ref_unit = ref_unit, city = city) {
    # function dependencies
    library(data.table, quietly = TRUE)
    library(survey, quietly = TRUE)

    # labels and indexes
    age_labels <- c("0-24", "25-49", "50-74", "+75")
    pop_stats <- fread("AEAT/data/pop-stats.csv")
    city_index <- pop_stats[muni == city & year == sel_year, index] %>% as.numeric()
    total_pop <- fread(paste0("AEAT/data/base/", city, "-sex.csv"))[year == sel_year, total]

    # reshape sex categories
    sex_vector <- fread(paste0("AEAT/data/", city, "-sex-freq.csv"))[, .(gender, Freq = get(paste0("freq", sel_year)))]

    # reshape age categories
    age_vector <- fread(paste0("AEAT/data/", city, "-age-freq.csv"))[, .(age_group, Freq = get(paste0("freq", sel_year)))]
    age_vector <- age_vector[, group := ceiling(.I / 5)][, .(Freq = sum(Freq)), by = group][, Freq := Freq * total_pop]
    age_vector <- cbind(age_group = age_labels, age_vector)[, group := NULL]

    # Create a new age_group based on broader 20-year intervals
    dt[, age_group := cut(
        AGE,
        breaks = c(0, 25, 50, 75, Inf), # Defining 20-year groups
        right = FALSE,
        labels = age_labels,
        include.lowest = TRUE
    )]
    dt <- dt[!is.na(age_group)]
    dt <- dt[!is.na(FACTORCAL)]
    dt[, gender := fifelse(SEXO == 1, "male", "female")]

    # Population totals for calibration
    calibration_totals <- list(
        sex_vector,
        age_vector
    )

    # Coerce gender and age group into named vectors
    gender_vector <- setNames(calibration_totals[[1]]$Freq, paste0("gender", calibration_totals[[1]]$gender))
    age_vector <- setNames(calibration_totals[[2]]$Freq, paste0("age_group", calibration_totals[[2]]$age_group))

    # Combine gender and age group vectors, and add RENTAB with a proper name
    calibration_totals_vec <- c(gender_vector, age_vector)

    # Prepare survey object
    dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL)
    pre_subsample <- subset(dt_sv, MUESTRA == city_index)

    # Apply calibration with the new named vector
    post_subsample <- calibrate(
        design = pre_subsample,
        formula = ~ -1 + gender + age_group,
        population = calibration_totals_vec
    )

    # Calibrate for mean income
    calibration_target <- c(
        RENTAB = RBpop * sum(post_subsample$variables[, FACTORCAL])
    )
    subsample <- calibrate(post_subsample, ~ -1 + RENTAB, calibration_target)

    # Update weights after calibration
    dt <- subsample$variables
    dt[, FACTORCAL := weights(subsample)]

    # return data with new weights
    return(dt)
}
