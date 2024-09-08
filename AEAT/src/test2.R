# Load required library
library(survey)

# Simulating a test sample dataset
set.seed(123)
sample_data <- data.frame(
  gender = sample(c("Male", "Female"), 100, replace = TRUE, prob = c(0.4, 0.6)),
  age_group = sample(c("18-24", "25-34", "35-44"), 100, replace = TRUE, prob = c(0.3, 0.5, 0.2)),
  income = rnorm(100, mean = 50000, sd = 10000)
)

# Population distribution known from census or other data
population_gender_dist <- c("Male" = 0.5, "Female" = 0.5)
population_age_dist <- c("18-24" = 0.2, "25-34" = 0.5, "35-44" = 0.3)

# 1. Post-Stratification

# Creating post-stratification design object
sample_data$weights <- 1  # Equal initial weights
design_ps <- svydesign(ids = ~1, data = sample_data, weights = ~weights)
mean_income_ps <- svymean(~income, design_ps)
cat("Mean income after pre-stratification:", mean_income_ps, "\n")


# Post-stratification table
post_strata <- data.frame(
  gender = c("Male", "Female"),
  Freq = c(0.5, 0.5) * 100
)

# Age post-stratification
age_strata <- data.frame(
  age_group = c("18-24", "25-34", "35-44"),
  Freq = c(0.2, 0.5, 0.3) * 100
)

# Apply post-stratification
design_ps <- postStratify(design_ps, ~gender, post_strata)
design_ps <- postStratify(design_ps, ~age_group, age_strata)

# Calculate mean income post-stratification
mean_income_ps <- svymean(~income, design_ps)
cat("Mean income after post-stratification:", mean_income_ps, "\n")

# 2. Bootstrap Re-sampling

# Function for bootstrap re-sampling
bootstrap_design <- function(data, indices) {
  d <- data[indices, ]
  svydesign(ids = ~1, data = d, weights = ~weights)
}

# Bootstrap with 1000 iterations
bootstrap_results <- boot::boot(
  data = sample_data,
  statistic = function(data, indices) {
    d <- bootstrap_design(data, indices)
    svymean(~income, d)
  },
  R = 1000
)

# Get the mean of bootstrapped income
mean_income_bootstrap <- mean(bootstrap_results$t)
cat("Mean income after bootstrapping:", mean_income_bootstrap, "\n")
