# Results from Alternative Calibrations

To perform custom recalibration of weights and evaluate their robustness for representative inference at the provincial geographic level, we use the script `representativity.R`, which enables a unified analysis. It can be executed with `$HOME/AEAT/src/tests/representativity.R` assuming `getwd() == $HOME`:

```r
source("$HOME/AEAT/src/tests/representativity.R", encoding = "UTF-8")
```

## Functions Needed to Reweight Subsamples from AEAT for Levels Below CCAA

The `get_wave` function is used by other scripts to establish both the target population and the analysis context.

- The parameter `city` specifies the target city for recalculating sample weights for representativeness.
- The parameter `sel_year` indicates the year to be analyzed.
- The parameter `represet` lets you choose the reference universe, with options like total population or tax filers as the reference unit.
- The parameter `ref_unit` sets the base identification level (choose between individuals and households).
- The parameter `calibrate` (boolean) allows for survey calibration by scaling against categorical variables (TIPOHOG) and continuous variables (RENTAB and RENTAD) for which population totals are known.

```r
# Get a sample weighted for a given city
dt <- get_wave(
    city = city, # Subregional unit
    sel_year = sel_year, # Wave
    ref_unit = ref_unit, # Reference PSU (either household or individual)
    represet = represet, # Reference universe/population (whole population or tax payers)
    calibrated = TRUE, # Requires auxiliary population data on mean RENTAD for the chosen city
    raked = rake_mode # Requires auxiliary population age and sex frequencies for the chosen city
)

# Define survey for the subsample of interest
subsample <- svydesign(
    ids = ~1,
    data = subset(dt, MUESTRA == city_index),
    weights = dt$FACTORCAL
)
```

Once our reweighted survey is available, we perform the following operations to test the robustness of our inference on key variables (income):

```r
# Calculate sample means
RNmean <- svymean(~RENTAD, subsample)
RBmean <- svymean(~RENTAB, subsample)

# Test if the survey means are equal to the population means
test_rep1 <- svycontrast(RNmean, quote(RENTAD - RNpop)) %>% as.numeric()
test_rep2 <- svycontrast(RBmean, quote(RENTAB - RBpop)) %>% as.numeric()

# Calculate p-values using a two-tailed test over t-statistics
p_val1 <- 2 * (1 - pnorm(abs(test_rep1 / SE(RNmean))))
p_val2 <- 2 * (1 - pnorm(abs(test_rep2 / SE(RBmean))))

# Prepare the results table with p-values
net_vals <- data.table(
    pop = RNpop,
    mean = coef(RNmean),
    stat = test_rep1,
    se = SE(RNmean),
    dif = (RNpop - coef(RNmean)) / RNpop,
    p_value = p_val1
)
gross_vals <- data.table(
    pop = RBpop,
    mean = coef(RBmean),
    stat = test_rep2,
    se = SE(RBmean),
    dif = (RBpop - coef(RBmean)) / RBpop,
    p_value = p_val2
)

# Combine and print the results
results <- rbind(net_vals, gross_vals, use.names = FALSE) %>% 
    round(3) %>% 
    print()

# Print sample sizes
sum(1 / subsample$variables[, "FACTORCAL"]) %>% print()
sum(subsample$variables[, "FACTORCAL"]) %>% print()
```

## Gross Uncalibrated Statistics

To achieve representativeness at the city scale, we need to adjust sample weights. Proper adjustment, given the AEAT panel structure:

```r
# Integrate AEAT structure into svydesign
dt_sv <- svydesign(
    ids = ~IDENHOG, # Household identifier for base PSU
    strata = ~ CCAA + TIPOHOG + TRAMO, # Region, household type, and income quantile
    data = dt,
    weights = dt$FACTORCAL,
    nest = TRUE # Households are nested within IDENPER and multiple REFCAT
)
```

CCAA-level adjusted "FACTORCAL" is necessary to avoid bias in key variable estimates, as shown in this example for Madrid city:

```r
## MADRID 2021: No raking or calibration
|--------------------------------------------------|
|==================================================|
     pop     mean     stat      se.    dif  p-value
   <num>    <num>    <num>     <num>  <num>  <num>
1: 43953 46373.09 2420.088   393.486 -0.055  0.000
2: 56453 59046.65 2593.646   546.964 -0.046  0.000
[1] 1301048
   Min. 1st Qu.   Median     Mean  3rd Qu.     Max.
 0.0018   1.1474   3.8811  16.7129  24.5950 600.7309
```

## Iteratively Calibrated Statistics on Proportions and Totals

We must apply a 2-step procedure to improve weights over the initial object (`dt_sv`):

1. **Step 1**: Reweight through iterative proportional fitting (IPS) on strata data.
2. **Step 2**: Calibrate on known total income (RENTAD).

Using R's survey package, the process involves using `calibrate` after defining our initial `svydesign` object:

```r
# Prepare survey object
dt_sv <- svydesign(
    ids = ~IDENHOG,
    strata = ~ CCAA + TIPOHOG + TRAMO,
    data = dt,
    weights = dt$FACTORCAL,
    nest = TRUE
)
pre_subsample <- subset(dt_sv, MUESTRA == city_index)
limits <- c(min(weights(pre_subsample)), max(weights(pre_subsample)))
calibration_totals_vec <- c(tipohog_pop, RENTAB = RBpop * sum(weights(pre_subsample)), RENTAD = RNpop * sum(weights(pre_subsample)))

# Apply calibration with the named vector
subsample <- calibrate(
    design = pre_subsample,
    formula = ~ -1 + TIPOHOG + RENTAB + RENTAD,
    population = calibration_totals_vec,
    calfun = "raking",
    bounds = limits,
    bounds.const = TRUE
)

dt <- subsample$variables
dt[, FACTORCAL := weights(subsample)]
```

The resulting updated statistics are as follows:

```r
## MADRID 2021: Calibrated
|--------------------------------------------------|
|==================================================|
     pop     mean     stat      se.    dif  p-value
   <num>    <num>    <num>     <num>  <num>  <num>
1: 43953 43730.03 -222.972 654.210 0.005   0.733
2: 56453 56166.62 -286.384 359.646 0.005   0.426
[1] "Implied Population Size Original:" 1307682
[1] "Implied Population Size Reweighted:" 1307682
[1] "Summary of Calibrated Weights"
   Min. 1st Qu.   Median     Mean  3rd Qu.     Max.
 0.0018   1.1541   3.5063  16.7981  18.6821 581.8978
```

As a result, mean differences (represented by "stat") are greatly reduced. For a standard 95% confidence level, we cannot reject the null hypothesis that the difference between the true population mean and our estimate is zero (as shown by p-values greater than 0.05 for both RENTAD and RENTAB).