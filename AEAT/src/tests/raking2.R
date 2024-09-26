# Rescale the raked weights to match Segovia's total population
total_population_segovia <- sum(survey_design_segovia$variables[,"FACTORCAL"])

# total_population_segovia <- sum(sex$segoT)
raked_weights <- raked_design$variables[,"FACTORCAL"]
rescaled_weights <- raked_weights * (total_population_segovia / sum(raked_weights))

# Update the survey design with the rescaled weights
raked_design <- update(raked_design, weights = rescaled_weights)

# Check the rescaled weights
print(rescaled_weights)

# Example analysis: Weighted mean of income after raking and rescaling
weighted_mean_income <- svymean(~RENTAD, raked_design)
preweighted_mean_income <- svymean(~RENTAD, survey_design)

# Output the results
print(weighted_mean_income)
print(preweighted_mean_income)

# Create the dt_post object from the raked_design variables
dt_post <- raked_design$variables %>% data.table()

# Assuming "IDENHOG" is the household identifier, we can group by it
# and summarize the variables of interest for each household
# For example, you can sum or average the variables for each household

# Example: Summing income-related variables and calculating the mean age for each household
dt_grouped <- dt_post[, .(
    RENTAD = sum(RENTAD, na.rm = TRUE), # Summing income RENTAD for the household
    RENTAB = sum(RENTAB, na.rm = TRUE), # Summing income RENTAB for the household
    PATINMO = sum(PATINMO, na.rm = TRUE), # Summing property assets for the household
    FACTORCAL = sum(weights, na.rm = TRUE) # Summing weights for the household
), by = IDENHOG]

# Create the survey grouped object with the initial weights
final_survey_design <- svydesign(
    ids = ~1,
    data = dt_grouped,
    weights = dt_grouped$FACTORCAL
) # Initial survey design with elevation factors
svymean(~RENTAD, final_survey_design) %>% print()

sum(final_survey_design$variables[,"FACTORCAL" ]) %>% print()
sum(raked_weights) %>% print()
sum(rescaled_weights) %>% print()
