source("LocalWealthHousing/AEAT/src/template.R")

# Create the survey design object with the initial weights
survey_design <- svydesign(
    ids = ~1,
    data = dt_sg,
    weights = dt_sg$FACTORCAL
) # Initial survey design with elevation factors

# Get the unique age groups from the sample data
unique_age_groups <- unique(dt_sg$age_group)

# Subset the population margin to include only age groups present in the sample
age_distribution2 <- age_distribution[age_group %in% unique_age_groups]


# Proceed with the raking process
raked_design <- rake(
    design = survey_design,
    sample.margins = list(~age_group, ~gender),
    population.margins = list(age_distribution2, gender_distribution),
    control = list(maxit = 10, epsilon = 1, verbose = FALSE)
)

# Rescale the raked weights to match Segovia's total population
total_population_segovia <- sum(sex$segoT)
raked_weights <- raked_design$variables[, "FACTORCAL"]
rescaled_weights <- raked_weights * (total_population_segovia / sum(raked_weights))
raked_design$variables[, "FACTORCAL"] <- rescaled_weights

raked_design2 <- update(raked_design, weights = raked_design$variables[, "FACTORCAL"])

svymean(~RENTAD, raked_design) %>% print()
svymean(~RENTAD, survey_design) %>% print()
svymean(~RENTAD, raked_design2) %>% print()

svymean(~RENTAB, raked_design) %>% print()
svymean(~RENTAB, survey_design) %>% print()
svymean(~RENTAB, raked_design2) %>% print()
