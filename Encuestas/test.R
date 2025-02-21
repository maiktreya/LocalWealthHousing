# Enhanced script for survey non-response handling with bootstrapping
# Designed for small samples and robust uncertainty quantification

library(magrittr) # pipes
library(data.table) # data wrangling
library(survey) # survey data
library(readxl) # read excel files
library(missRanger) # to impute values
library(openxlsx) # for writing Excel files
library(boot) # for bootstrap procedures
library(ggplot2) # for diagnostic plots
library(gridExtra) # for arranging multiple plots

# Prepare environment
gc()
rm(list = ls())

# ========== DATA LOADING & CLEANING ==========

# Read original forms
ie_forms <- read_excel("Encuestas/input/IE.2025.xlsx") %>% data.table()
uv_forms <- read_excel("Encuestas/input/UVA.2025.xlsx") %>% data.table()

# Convert datetime columns properly
ie_forms[, `hora_de_inicio` := as.POSIXct(`hora_de_inicio`, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")]
uv_forms[, `hora_de_inicio` := as.POSIXct(`hora_de_inicio`, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")]

# Exclude non-imputable variables
exclude_vars <- c("hora_de_inicio", "hora_de_finalizacion", "id")
ie_clean <- ie_forms[, !exclude_vars, with = FALSE]
uv_clean <- uv_forms[, !exclude_vars, with = FALSE]

# Convert empty strings to NA
ie_clean[ie_clean == ""] <- NA
uv_clean[uv_clean == ""] <- NA

# Ensure consistent column types with more nuanced handling
prepare_data <- function(dt) {
    for (col in names(dt)) {
        if (is.character(dt[[col]])) {
            # Check if it's likely a numeric variable that was read as character
            if (all(grepl("^[0-9.]+$", na.omit(dt[[col]])))) {
                dt[[col]] <- as.numeric(dt[[col]])
            } else {
                dt[[col]] <- as.factor(dt[[col]])
            }
        }
    }
    return(dt)
}

ie_clean <- prepare_data(ie_clean)
uv_clean <- prepare_data(uv_clean)

# ========== MISSING DATA DIAGNOSTICS ==========

# Function to analyze missingness patterns
analyze_missingness <- function(dt, name) {
    # Calculate missingness by variable
    miss_var <- colSums(is.na(dt)) / nrow(dt)

    # Calculate missingness by observation
    miss_obs <- rowSums(is.na(dt)) / ncol(dt)

    # Plot missingness patterns
    par(mfrow = c(1, 2))
    barplot(miss_var,
        main = paste0("Missingness by Variable (", name, ")"),
        ylab = "Proportion Missing", las = 2, cex.names = 0.7
    )
    hist(miss_obs,
        main = paste0("Missingness by Observation (", name, ")"),
        xlab = "Proportion of Variables Missing"
    )

    # Check for variables with high missingness (potential exclusion)
    high_miss_vars <- names(miss_var[miss_var > 0.5])

    # Return diagnostic information
    return(list(
        dataset = name,
        n_obs = nrow(dt),
        n_vars = ncol(dt),
        overall_missingness = mean(is.na(dt)),
        vars_high_missingness = high_miss_vars,
        miss_by_var = miss_var,
        miss_by_obs = miss_obs
    ))
}

ie_miss <- analyze_missingness(ie_clean, "IE")
uv_miss <- analyze_missingness(uv_clean, "UV")

# Create diagnostic summary
miss_summary <- data.frame(
    Dataset = c("IE", "UV"),
    Sample_Size = c(nrow(ie_clean), nrow(uv_clean)),
    Overall_Missingness = c(ie_miss$overall_missingness, uv_miss$overall_missingness),
    Vars_High_Missing = c(
        paste(ie_miss$vars_high_missingness, collapse = ", "),
        paste(uv_miss$vars_high_missingness, collapse = ", ")
    )
)

write.xlsx(miss_summary, "Encuestas/svy_reports/missingness_summary.xlsx")

# ========== MULTIPLE IMPUTATION WITH BOOTSTRAPPING ==========

# Number of bootstrap samples and imputations
n_boots <- 100
n_imps <- 20

# Function to create bootstrap samples with imputation
bootstrap_impute <- function(dt, n_boots, n_imps) {
    boot_results <- list()

    for (b in 1:n_boots) {
        # Create bootstrap sample (with replacement)
        boot_idx <- sample(1:nrow(dt), nrow(dt), replace = TRUE)
        boot_sample <- dt[boot_idx, ]

        # Create multiple imputations for this bootstrap sample
        imp_list <- replicate(
            n_imps,
            missRanger(
                boot_sample,
                verbose = 0,
                num.trees = 100,
                pmm.k = min(10, nrow(boot_sample) / 3), # Adjust pmm.k based on sample size
                respect.unordered.factors = TRUE,
                seed = b * 1000 + 1:n_imps
            ),
            simplify = FALSE
        )

        boot_results[[b]] <- list(
            boot_idx = boot_idx,
            imputations = imp_list
        )
    }

    return(boot_results)
}

# Apply bootstrap imputation
set.seed(8675309) # For reproducibility
ie_boot_imp <- bootstrap_impute(ie_clean, n_boots, n_imps)
uv_boot_imp <- bootstrap_impute(uv_clean, n_boots, n_imps)

# ========== ESTIMATE STATISTICS WITH UNCERTAINTY ==========

# Function to calculate statistics across bootstrap samples
calculate_bootstrap_stats <- function(boot_imp_results, original_data) {
    all_vars <- names(original_data)
    result_stats <- list()

    # Iterate through all variables
    for (var in all_vars) {
        if (is.numeric(original_data[[var]])) {
            # For numeric variables, calculate mean and quantiles
            all_means <- numeric(length(boot_imp_results))

            for (b in 1:length(boot_imp_results)) {
                # Average across imputations for this bootstrap
                imp_means <- sapply(boot_imp_results[[b]]$imputations, function(x) mean(x[[var]], na.rm = TRUE))
                all_means[b] <- mean(imp_means)
            }

            result_stats[[var]] <- list(
                type = "numeric",
                original_mean = mean(original_data[[var]], na.rm = TRUE),
                original_n_obs = sum(!is.na(original_data[[var]])),
                boot_mean = mean(all_means),
                boot_se = sd(all_means),
                boot_ci_lower = quantile(all_means, 0.025),
                boot_ci_upper = quantile(all_means, 0.975)
            )
        } else if (is.factor(original_data[[var]])) {
            # For categorical variables, calculate proportions for each level
            levels_list <- levels(original_data[[var]])
            level_props <- list()

            for (lvl in levels_list) {
                all_props <- numeric(length(boot_imp_results))

                for (b in 1:length(boot_imp_results)) {
                    # Average across imputations for this bootstrap
                    imp_props <- sapply(boot_imp_results[[b]]$imputations, function(x) {
                        mean(x[[var]] == lvl, na.rm = TRUE)
                    })
                    all_props[b] <- mean(imp_props)
                }

                level_props[[lvl]] <- list(
                    original_prop = mean(original_data[[var]] == lvl, na.rm = TRUE),
                    original_n_obs = sum(original_data[[var]] == lvl, na.rm = TRUE),
                    boot_prop = mean(all_props),
                    boot_se = sd(all_props),
                    boot_ci_lower = quantile(all_props, 0.025),
                    boot_ci_upper = quantile(all_props, 0.975)
                )
            }

            result_stats[[var]] <- list(
                type = "categorical",
                levels = level_props
            )
        }
    }

    return(result_stats)
}

# Calculate statistics
ie_stats <- calculate_bootstrap_stats(ie_boot_imp, ie_clean)
uv_stats <- calculate_bootstrap_stats(uv_boot_imp, uv_clean)

# ========== CREATE FINAL DATASETS WITH DIAGNOSTICS ==========

# Function to compile results into data frames
compile_numeric_results <- function(stats_list) {
    numeric_vars <- names(stats_list)[sapply(stats_list, function(x) x$type == "numeric")]

    if (length(numeric_vars) == 0) {
        return(NULL)
    }

    result_df <- data.frame(
        Variable = numeric_vars,
        Original_Mean = sapply(stats_list[numeric_vars], function(x) x$original_mean),
        Original_N = sapply(stats_list[numeric_vars], function(x) x$original_n_obs),
        Bootstrap_Mean = sapply(stats_list[numeric_vars], function(x) x$boot_mean),
        Bootstrap_SE = sapply(stats_list[numeric_vars], function(x) x$boot_se),
        CI_Lower = sapply(stats_list[numeric_vars], function(x) x$boot_ci_lower),
        CI_Upper = sapply(stats_list[numeric_vars], function(x) x$boot_ci_upper),
        CV = sapply(stats_list[numeric_vars], function(x) x$boot_se / x$boot_mean)
    )

    return(result_df)
}

compile_categorical_results <- function(stats_list) {
    cat_vars <- names(stats_list)[sapply(stats_list, function(x) x$type == "categorical")]

    if (length(cat_vars) == 0) {
        return(NULL)
    }

    result_rows <- list()

    for (var in cat_vars) {
        levels_list <- names(stats_list[[var]]$levels)

        for (lvl in levels_list) {
            level_stats <- stats_list[[var]]$levels[[lvl]]

            result_rows[[length(result_rows) + 1]] <- data.frame(
                Variable = var,
                Level = lvl,
                Original_Prop = level_stats$original_prop,
                Original_N = level_stats$original_n_obs,
                Bootstrap_Prop = level_stats$boot_prop,
                Bootstrap_SE = level_stats$boot_se,
                CI_Lower = level_stats$boot_ci_lower,
                CI_Upper = level_stats$boot_ci_upper,
                CV = level_stats$boot_se / level_stats$boot_prop
            )
        }
    }

    result_df <- do.call(rbind, result_rows)
    return(result_df)
}

# Compile results
ie_numeric_results <- compile_numeric_results(ie_stats)
ie_categorical_results <- compile_categorical_results(ie_stats)
uv_numeric_results <- compile_numeric_results(uv_stats)
uv_categorical_results <- compile_categorical_results(uv_stats)

# Save diagnostic results
write.xlsx(list(
    IE_Numeric = ie_numeric_results,
    IE_Categorical = ie_categorical_results,
    UV_Numeric = uv_numeric_results,
    UV_Categorical = uv_categorical_results,
    Missingness_Summary = miss_summary
), "Encuestas/svy_reports/bootstrap_imputation_results.xlsx")

# ========== CREATE FINAL IMPUTED DATASETS ==========

# Function to create a single "best" imputed dataset based on bootstrap results
create_final_dataset <- function(original_data, boot_imp_results) {
    final_data <- original_data

    for (col in names(original_data)) {
        missing_idx <- which(is.na(original_data[[col]]))

        if (length(missing_idx) > 0) {
            if (is.numeric(original_data[[col]])) {
                # For numeric variables, take the bootstrap mean of imputed values
                imputed_values <- numeric(length(missing_idx))

                for (i in seq_along(missing_idx)) {
                    idx <- missing_idx[i]
                    values_across_boots <- numeric(length(boot_imp_results))

                    for (b in 1:length(boot_imp_results)) {
                        boot_idx <- boot_imp_results[[b]]$boot_idx
                        # Find positions where this original index appears in the bootstrap sample
                        boot_positions <- which(boot_idx == idx)

                        if (length(boot_positions) > 0) {
                            # Take mean across imputations for these positions
                            imp_values <- sapply(boot_imp_results[[b]]$imputations, function(x) {
                                mean(x[[col]][boot_positions], na.rm = TRUE)
                            })
                            values_across_boots[b] <- mean(imp_values, na.rm = TRUE)
                        }
                    }

                    # Remove NAs and calculate final imputed value
                    values_across_boots <- values_across_boots[!is.na(values_across_boots)]
                    if (length(values_across_boots) > 0) {
                        imputed_values[i] <- mean(values_across_boots)
                    } else {
                        # Fallback if no imputations available
                        imputed_values[i] <- mean(original_data[[col]], na.rm = TRUE)
                    }
                }

                final_data[[col]][missing_idx] <- imputed_values
            } else if (is.factor(original_data[[col]])) {
                # For categorical variables, take most frequent imputed value
                for (i in seq_along(missing_idx)) {
                    idx <- missing_idx[i]
                    all_imputed_values <- character()

                    for (b in 1:length(boot_imp_results)) {
                        boot_idx <- boot_imp_results[[b]]$boot_idx
                        boot_positions <- which(boot_idx == idx)

                        if (length(boot_positions) > 0) {
                            for (imp in boot_imp_results[[b]]$imputations) {
                                all_imputed_values <- c(all_imputed_values, as.character(imp[[col]][boot_positions]))
                            }
                        }
                    }

                    if (length(all_imputed_values) > 0) {
                        most_frequent <- names(sort(table(all_imputed_values), decreasing = TRUE)[1])
                        final_data[[col]][idx] <- most_frequent
                    }
                }
            }
        }
    }

    return(final_data)
}

# Create final datasets
final_IE <- create_final_dataset(ie_clean, ie_boot_imp)
final_UV <- create_final_dataset(uv_clean, uv_boot_imp)

# Add imputation flags
for (col in names(ie_clean)) {
    final_IE[[paste0(col, "_imputed")]] <- is.na(ie_clean[[col]])
}

for (col in names(uv_clean)) {
    final_UV[[paste0(col, "_imputed")]] <- is.na(uv_clean[[col]])
}

# Save final datasets
write.xlsx(final_IE, "Encuestas/output/IE_final_imputed.xlsx")
write.xlsx(final_UV, "Encuestas/output/UV_final_imputed.xlsx")

# Create diagnostic plot function for final results
create_diagnostic_plots <- function(original, imputed, var_name) {
    if (is.numeric(original[[var_name]])) {
        # For numeric variables
        p1 <- ggplot() +
            geom_density(aes(x = original[[var_name]], fill = "Original"), alpha = 0.5) +
            geom_density(aes(x = imputed[[var_name]], fill = "Imputed"), alpha = 0.5) +
            labs(
                title = paste("Distribution Comparison for", var_name),
                x = var_name, y = "Density"
            ) +
            scale_fill_manual(
                values = c("Original" = "blue", "Imputed" = "red"),
                name = "Data Source"
            ) +
            theme_minimal()

        missing_idx <- which(is.na(original[[var_name]]))
        if (length(missing_idx) > 0) {
            imputed_values <- imputed[[var_name]][missing_idx]
            p2 <- ggplot() +
                geom_histogram(aes(x = imputed_values), fill = "red", alpha = 0.7, bins = 30) +
                labs(
                    title = paste("Distribution of Imputed Values for", var_name),
                    x = var_name, y = "Count"
                ) +
                theme_minimal()
        } else {
            p2 <- ggplot() +
                annotate("text", x = 0.5, y = 0.5, label = "No missing values") +
                theme_void()
        }

        return(list(p1, p2))
    } else if (is.factor(original[[var_name]])) {
        # For categorical variables
        orig_complete <- original[!is.na(original[[var_name]]), ]
        orig_props <- prop.table(table(orig_complete[[var_name]]))
        imp_props <- prop.table(table(imputed[[var_name]]))

        # Combine into a data frame
        levels_all <- unique(c(names(orig_props), names(imp_props)))
        plot_data <- data.frame(
            Level = rep(levels_all, 2),
            Proportion = c(
                sapply(levels_all, function(l) if (l %in% names(orig_props)) orig_props[l] else 0),
                sapply(levels_all, function(l) if (l %in% names(imp_props)) imp_props[l] else 0)
            ),
            Source = rep(c("Original", "Imputed"), each = length(levels_all))
        )

        p1 <- ggplot(plot_data, aes(x = Level, y = Proportion, fill = Source)) +
            geom_bar(stat = "identity", position = "dodge", alpha = 0.7) +
            labs(
                title = paste("Distribution Comparison for", var_name),
                x = "Category", y = "Proportion"
            ) +
            scale_fill_manual(values = c("Original" = "blue", "Imputed" = "red")) +
            theme_minimal() +
            theme(axis.text.x = element_text(angle = 45, hjust = 1))

        # Only imputed values
        missing_idx <- which(is.na(original[[var_name]]))
        if (length(missing_idx) > 0) {
            imputed_values <- imputed[[var_name]][missing_idx]
            p2 <- ggplot(data.frame(Value = imputed_values), aes(x = Value)) +
                geom_bar(fill = "red", alpha = 0.7) +
                labs(
                    title = paste("Distribution of Imputed Values for", var_name),
                    x = "Category", y = "Count"
                ) +
                theme_minimal() +
                theme(axis.text.x = element_text(angle = 45, hjust = 1))
        } else {
            p2 <- ggplot() +
                annotate("text", x = 0.5, y = 0.5, label = "No missing values") +
                theme_void()
        }

        return(list(p1, p2))
    }
}

# Create diagnostic plots for key variables
key_vars_ie <- names(ie_clean)[1:min(5, ncol(ie_clean))] # First 5 variables as example
key_vars_uv <- names(uv_clean)[1:min(5, ncol(uv_clean))]

for (var in key_vars_ie) {
    plots <- create_diagnostic_plots(ie_clean, final_IE, var)
    pdf(paste0("Encuestas/IE_", var, "_diagnostic.pdf"), width = 10, height = 6)
    grid.arrange(plots[[1]], plots[[2]], ncol = 2)
    dev.off()
}

for (var in key_vars_uv) {
    plots <- create_diagnostic_plots(uv_clean, final_UV, var)
    pdf(paste0("Encuestas/UV_", var, "_diagnostic.pdf"), width = 10, height = 6)
    grid.arrange(plots[[1]], plots[[2]], ncol = 2)
    dev.off()
}

print("Bootstrap imputation procedure complete with diagnostics.")
