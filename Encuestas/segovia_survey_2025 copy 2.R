library(magrittr) # pipes
library(data.table) # data wrangling
library(survey) # survey data
library(readxl) # read excel files
library(mice) # library for dealing with multiple imputations
library(mi)
library(MASS) # for synthetic data generation
library(dplyr)

# Prepare environment by cleaning any previous object in memory
gc()
rm(list = ls())

# Read original forms
ie_forms <- read_excel("Encuestas/IE.2025.treated.xlsx", sheet = "Final") %>% data.table()

# Convert 'Start time' to POSIXct format to avoid errors
ie_forms[, `Start time` := as.POSIXct(`Start time`, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")]
# Ensure consistent column types
ie_forms[] <- lapply(ie_forms, function(x) if (is.character(x)) as.factor(x) else x)

# Exclude non-imputable variables
exclude_vars <- colnames(ie_forms)[c(1, 4, (15:length(colnames(ie_forms))))]
original_data <- ie_forms[, !exclude_vars, with = FALSE]

# Function to generate synthetic survey records
generate_survey_records <- function(original_data, n_synthetic = 1000, seed = 123) {
    # Set seed for reproducibility
    set.seed(seed)

    # Convert data.table to data.frame for compatibility
    original_data <- as.data.frame(original_data)

    # Function to determine variable type and generate synthetic values
    generate_column <- function(col) {
        if (is.factor(col)) {
            # For categorical variables, sample from original distribution
            # Get factor levels and their frequencies
            lvls <- levels(col)
            freq_table <- table(col)

            # Ensure we have frequencies for all levels
            freq_vector <- numeric(length(lvls))
            names(freq_vector) <- lvls
            freq_vector[names(freq_table)] <- freq_table

            # Calculate probabilities, handling zero frequencies
            probs <- freq_vector / sum(freq_vector)
            probs[is.na(probs)] <- 0

            # Generate synthetic values
            synthetic_valulvlses <- sample(, n_synthetic, replace = TRUE, prob = probs)
            factor(synthetic_values, levels = lvls)
        } else if (is.numeric(col)) {
            # For continuous variables, sample from kernel density estimate
            if (length(unique(na.omit(col))) > 1) { # Check if we have enough unique values
                density_est <- density(col, na.rm = TRUE)
                sampled_values <- sample(density_est$x, n_synthetic,
                    replace = TRUE,
                    prob = density_est$y
                )
                # Ensure values stay within original range
                pmin(
                    pmax(sampled_values, min(col, na.rm = TRUE)),
                    max(col, na.rm = TRUE)
                )
            } else {
                # If only one unique value, replicate it
                rep(col[1], n_synthetic)
            }
        } else {
            # For other types, just sample from original
            sample(as.character(col), n_synthetic, replace = TRUE)
        }
    }

    # Generate synthetic data for each column
    synthetic_data <- as.data.frame(lapply(original_data, function(col) {
        tryCatch(
            {
                generate_column(col)
            },
            error = function(e) {
                warning(paste(
                    "Error generating synthetic data for column:",
                    deparse(substitute(col)), "\nError:", e$message
                ))
                # Return NA vector as fallback
                rep(NA, n_synthetic)
            }
        )
    }))

    # Preserve correlations between numeric variables
    numeric_cols <- sapply(original_data, is.numeric)
    if (sum(numeric_cols) >= 2) {
        # Get correlation matrix of original numeric variables
        cor_matrix <- cor(original_data[, numeric_cols], use = "pairwise.complete.obs")

        # Generate multivariate normal data with same correlation structure
        mvn_data <- mvrnorm(n_synthetic,
            mu = colMeans(original_data[, numeric_cols], na.rm = TRUE),
            Sigma = cor_matrix
        )

        # Transform to match original distributions
        for (i in 1:ncol(mvn_data)) {
            col_name <- names(original_data)[numeric_cols][i]
            orig_ranks <- rank(original_data[[col_name]], na.last = "keep")
            synthetic_data[[col_name]] <- sort(synthetic_data[[col_name]])[
                rank(mvn_data[, i], ties.method = "random")
            ]
        }
    }

    # Convert back to data.table
    synthetic_data <- as.data.table(synthetic_data)

    return(synthetic_data)
}

# Generate synthetic records with error handling
n_synthetic <- 1000 # Adjust this number as needed
tryCatch(
    {
        synthetic_ie_forms <- generate_survey_records(original_data, n_synthetic = n_synthetic)

        # Add back excluded variables with appropriate synthetic values
        for (var in exclude_vars) {
            if (var %in% colnames(ie_forms)) {
                if (is.factor(ie_forms[[var]]) || is.character(ie_forms[[var]])) {
                    lvls <- unique(ie_forms[[var]])
                    synthetic_ie_forms[, (var) := sample(lvls, n_synthetic, replace = TRUE)]
                } else if (var == "Start time") {
                    # Generate random timestamps within the range of original data
                    min_time <- min(ie_forms$`Start time`, na.rm = TRUE)
                    max_time <- max(ie_forms$`Start time`, na.rm = TRUE)
                    synthetic_ie_forms[, (var) := as.POSIXct(
                        sample(seq(min_time, max_time, by = "mins"), n_synthetic, replace = TRUE)
                    )]
                }
            }
        }

        # Save synthetic data
        fwrite(synthetic_ie_forms, "Encuestas/IE.2025.synthetic.csv")
    },
    error = function(e) {
        message("Error in synthetic data generation: ", e$message)
    }
)

# Compare distributions function
compare_distributions <- function(original, synthetic, var_name) {
    tryCatch(
        {
            if (is.factor(original[[var_name]]) || is.character(original[[var_name]])) {
                # For categorical variables
                orig_prop <- prop.table(table(original[[var_name]], useNA = "ifany"))
                synt_prop <- prop.table(table(synthetic[[var_name]], useNA = "ifany"))
                print(paste("Distribution comparison for", var_name))
                print("Original proportions:")
                print(orig_prop)
                print("Synthetic proportions:")
                print(synt_prop)
            } else if (is.numeric(original[[var_name]])) {
                # For numeric variables
                print(paste("Summary statistics for", var_name))
                print("Original:")
                print(summary(original[[var_name]]))
                print("Synthetic:")
                print(summary(synthetic[[var_name]]))
            }
        },
        error = function(e) {
            warning(paste("Error comparing distributions for variable:", var_name, "\nError:", e$message))
        }
    )
}

# Compare distributions for a few key variables
for (var in names(original_data)[1:min(5, ncol(original_data))]) {
    compare_distributions(original_data, synthetic_ie_forms, var)
}
