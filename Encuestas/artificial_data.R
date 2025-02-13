library(survey)
library(dplyr)
library(MASS) # For mvrnorm function

generate_survey_records <- function(original_data, n_synthetic = 1000, seed = 123) {
  # Set seed for reproducibility
  set.seed(seed)
  
  # Function to determine variable type and generate synthetic values
  generate_column <- function(col) {
    if (is.factor(col) || is.character(col)) {
      # For categorical variables, sample from original distribution
      sample(col, n_synthetic, replace = TRUE, 
             prob = table(col) / length(col))
    } else if (is.numeric(col)) {
      # For continuous variables, sample from kernel density estimate
      density_est <- density(col, na.rm = TRUE)
      sampled_values <- sample(density_est$x, n_synthetic, 
                              replace = TRUE, 
                              prob = density_est$y)
      # Ensure values stay within original range
      pmin(pmax(sampled_values, min(col, na.rm = TRUE)), 
           max(col, na.rm = TRUE))
    } else {
      # For other types, just sample from original
      sample(col, n_synthetic, replace = TRUE)
    }
  }
  
  # Generate synthetic data for each column
  synthetic_data <- as.data.frame(lapply(original_data, generate_column))
  
  # Preserve correlations between numeric variables
  numeric_cols <- sapply(original_data, is.numeric)
  if (sum(numeric_cols) >= 2) {
    # Get correlation matrix of original numeric variables
    cor_matrix <- cor(original_data[, numeric_cols], use = "pairwise.complete.obs")
    
    # Generate multivariate normal data with same correlation structure
    mvn_data <- mvrnorm(n_synthetic, 
                        mu = colMeans(original_data[, numeric_cols], na.rm = TRUE),
                        Sigma = cor_matrix)
    
    # Transform to match original distributions
    for (i in 1:ncol(mvn_data)) {
      col_name <- names(original_data)[numeric_cols][i]
      orig_ranks <- rank(original_data[[col_name]], na.last = "keep")
      synthetic_data[[col_name]] <- sort(synthetic_data[[col_name]])[
        rank(mvn_data[, i], ties.method = "random")
      ]
    }
  }
  
  # Add survey design elements if present in original data
  if ("weights" %in% names(attributes(original_data))) {
    # Generate synthetic weights based on original distribution
    synthetic_data$weights <- generate_column(weights(original_data))
  }
  
  # Add any stratification variables if present
  if (!is.null(attr(original_data, "strata"))) {
    strata_var <- attr(original_data, "strata")
    synthetic_data[[strata_var]] <- generate_column(original_data[[strata_var]])
  }
  
  return(synthetic_data)
}

# Example usage:
# Assuming 'survey_data' is your original survey dataset with survey design
# synthetic_records <- generate_survey_records(survey_data, n_synthetic = 1000)

# Creating a survey design object with the synthetic data
# synthetic_design <- svydesign(
#   ids = ~1,  # For simple random sampling
#   weights = ~weights,  # If weights were generated
#   strata = ~strata,    # If strata were generated
#   data = synthetic_records
# )