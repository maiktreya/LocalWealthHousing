# Load required library
library(survey)

# Create survey design
design <- svydesign(ids = ~1, data = sample_data, weights = ~weights)

# Specify population means and categorical proportions
pop_mean_income <- 55000  # Example population mean
pop_gender_dist <- c(Male = 0.5, Female = 0.5)
pop_age_dist <- c("18-24" = 0.2, "25-34" = 0.5, "35-44" = 0.3)

# Use raking to adjust weights to match population distributions
rake_design <- rake(design,
                    sample.margins = list(~gender, ~age_group),
                    population.margins = list(pop_gender_dist, pop_age_dist),
                    income.target = pop_mean_income)  # Rake on income as well
