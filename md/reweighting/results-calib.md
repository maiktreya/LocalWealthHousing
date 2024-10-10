# Results from alternative calibrations

## Gross uncalibrated statistics

To achieve representativeness at the city scale we need to adjust sample weights. To do this properly, given AEAT panel de renta structure:

```r
# AEAT structure integrated into svydesign
    dt_sv <- svydesign(
        ids = ~IDENHOG, # household identifier for base PSU
        strata = ~ CCAA + TIPOHOG + TRAMO, # region, type of household and income quantile
        data = dt,
        weights = dt$FACTORCAL,
        nest = TRUE # households are nested inside IDENPER and multiple REFCAT
    )
```

We have to adjust the CCAA level adjusted "FACTORCAL". Otherwise, estimated statistics for key variables would be biased as shown with this example performed on Madrid city: (1: RENTAD, 2: RENTAB)

```r
## MADRID 2021: no raking or calibration
|--------------------------------------------------|
|==================================================|
     pop     mean     stat      se.    dif  p-value
   <num>    <num>    <num>     <num>  <num>  <num>
1: 43953 46373.09 2420.088   393.486 -0.055  0.000
2: 56453 59046.65 2593.646   546.964 -0.046  0.000
[1] 1301048
    Min.  1st Qu.   Median     Mean  3rd Qu.     Max.
  0.0018   1.1474   3.8811  16.7129  24.5950 600.7309


  ## MADRID 2016: no raking or calibration
|--------------------------------------------------|
|==================================================|
     pop     mean     stat      se.    dif  p-value
   <num>    <num>   <num>     <num>  <num>  <num>
1: 39613 40537.71 924.713   286.155 -0.023  0.001
2: 49831 50683.07 852.066   381.496 -0.017  0.026
[1] 1254462
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
  1.111   2.847   6.400  25.483  31.442 575.520
```


## Iteratively calibrated statistics on proportions and total values

For that reason We must apply a 2step procedure to improve weights over that initial object (dt_sv):

* STEP1: reweighting through iterative proportional fitting (IPS) on strata data
* STEP2: calibrate on known total income (RENTAD)

Using R survey package it would imply using calibrate after defining our original surveydesign objecto:

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

# Apply calibration with the new named vector
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
Afterwards, we get the following updated results:

```r
## MADRID 2021: calibrated
|--------------------------------------------------|
|==================================================|
     pop     mean     stat      se.    dif  p-value
   <num>    <num>    <num>     <num>  <num>  <num>
     pop     mean     stat      se  dif% p_value
   <num>    <num>    <num>   <num> <num>   <num>
1: 43953 43730.03 -222.972 654.210 0.005   0.733
2: 56453 56166.62 -286.384 359.646 0.005   0.426
[1] "Sample size original:"
[1] 1307682
[1] "Sample size Reweighted:"
[1] 1307682
[1] "Summary of calibrated weights"
    Min.  1st Qu.   Median     Mean  3rd Qu.     Max.
  0.0018   1.1541   3.5063  16.7981  18.6821 581.8978

## MADRID 2016: calibrated
|--------------------------------------------------|
|==================================================|
     pop     mean      stat       se  dif%  p_value
   <num>    <num>     <num>    <num> <num>    <num>
1: 39613 39611.40 -1.599000 365.9960 0e+00 0.997000
2: 49831 49828.99 -2.012039 547.7889 4e-05 0.997069
[1] "Sample size original:"
[1] 1254513
[1] "Sample size Reweighted:"
[1] 1254513
[1] "Summary of calibrated weights"
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
  1.111   2.253   6.920  25.484  32.906 575.520
```

As a result mean differences (represented by "stat") greatly diminished and, for a standard 95% confidence level, we could not reject the null hypothesis of the difference between the true population mean and our prediction being 0 (as reflected by "p-value" greater than 0.05 in all cases, both for RENTAD and RENTAB).