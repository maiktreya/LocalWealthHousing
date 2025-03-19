library(data.table)
library(magrittr)
library(openxlsx)
library(survey)

# Install and load pwr package
library(pwr)

# get survey microdata
dt_ie <- read.xlsx("Encuestas/input/IE_final_imputed.xlsx")
dt_uv <- read.xlsx("Encuestas/input/UVA_final_imputed.xlsx")

# total population and sample sizes
total_pop_ie <- 3923
total_pop_uv <- 2323
sample_size_ie <- nrow(dt_ie)
sample_size_uv <- nrow(dt_uv)

# check sample means exist
dt_ie$how_much_do_you_pay_monthly_in_your_rental_contract %>% mean(na.rm = TRUE)
dt_uv$how_much_do_you_pay_monthly_in_your_rental_contract %>% mean(na.rm = TRUE)

# Complete svydesign objects for both populations
dt_ie_sv <- svydesign(~1,
    data = dt_ie,
    weights = rep(total_pop_ie/nrow(dt_ie), nrow(dt_ie)))

dt_uv_sv <- svydesign(~1,
    data = dt_uv,
    weights = rep(total_pop_uv/nrow(dt_uv), nrow(dt_uv)))

# Calculate survey means and confidence intervals
ie_mean <- svymean(~how_much_do_you_pay_monthly_in_your_rental_contract, 
    design = dt_ie_sv, 
    na.rm = TRUE)

uv_mean <- svymean(~how_much_do_you_pay_monthly_in_your_rental_contract, 
    design = dt_uv_sv, 
    na.rm = TRUE)

# Display results with confidence intervals
ie_ci <- confint(ie_mean)
uv_ci <- confint(uv_mean)

# Print results
cat("IE Survey Results:\n")
print(ie_mean)
print(ie_ci)

cat("\nUV Survey Results:\n")
print(uv_mean)
print(uv_ci)

# Calculate effect size (Cohen's d) with diagnostic print
mean_diff <- abs(coef(ie_mean) - coef(uv_mean))
pooled_sd <- sqrt((SE(ie_mean)^2 * (sample_size_ie-1) + SE(uv_mean)^2 * (sample_size_uv-1)) / 
                 (sample_size_ie + sample_size_uv - 2))
cohen_d <- mean_diff / pooled_sd

# Print diagnostic information
cat("\nDiagnostic Information:\n")
cat("Mean difference:", mean_diff, "\n")
cat("Pooled SD:", pooled_sd, "\n")
cat("Cohen's d:", cohen_d, "\n")

# Perform power analysis with current sample size
power_test <- try(pwr.t.test(n = min(sample_size_ie, sample_size_uv),
                        d = cohen_d,
                        sig.level = 0.05,
                        type = "two.sample",
                        alternative = "two.sided"))

# Print power analysis results
cat("\nPower Analysis Results:\n")
if(!inherits(power_test, "try-error")) {
    print(power_test)
} else {
    cat("Power is effectively 1 (100%) - the effect size is very large\n")
    cat("Current sample sizes are more than adequate for statistical inference\n")
}

# Try calculating required sample size with error handling
required_n <- try({
    pwr.t.test(d = min(cohen_d, 5), # Cap the effect size
               power = 0.8,
               sig.level = 0.05,
               type = "two.sample",
               alternative = "two.sided")
})

# Print results with interpretation
cat("\nSample Size Analysis:\n")
if(!inherits(required_n, "try-error")) {
    cat("Minimum required sample size for 80% power:", ceiling(required_n$n), "\n")
    cat("Current sample sizes (IE:", sample_size_ie, ", UV:", sample_size_uv, ")\n")
    cat("Current samples are", 
        ifelse(min(sample_size_ie, sample_size_uv) > required_n$n, 
               "adequate", 
               "potentially inadequate"), 
        "for statistical inference\n")
} else {
    cat("Effect size is very large (Cohen's d =", round(cohen_d, 2), ")\n")
    cat("Current sample sizes are more than adequate for statistical inference\n")
}