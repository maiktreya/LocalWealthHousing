## Model used for calibration (shared by 2016 and 2021)

```r
    # Post-stratify by household type
    sv_design <- postStratify(
        design = sv_design_base,
        strata = ~TIPOHOG1,
        population = tipohog_pop
    )
    # Apply calibration with TIPOHOG1
    calibrated_design <- calibrate(
        design = sv_design,
        formula = ~ -1 + RENTAB,
        population = calibration_totals_vec,
        bounds = c(0, limits[2]),
        bounds.const = TRUE,
        calfun = "linear",
        maxit = 20000
    )
```
---
## 2 STEP CALIBRATED 2016
---

```r
      var   pop     mean    stat      SE   RSE    dif  pval   MOE
1: RENTAD 39613 39724.90 111.897 249.462 0.006 -0.003 0.654 0.012
2: RENTAB 49831 50032.86 201.862 337.527 0.007 -0.004 0.550 0.013
[1] "Implied Pop. size Reweighted:"
[1] 1254462
[1] "Summary of calibrated weights"
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
  0.000   2.859   6.426  25.483  31.347 577.582
```

## 1 STEP CALIBRATED 2021

---

```r
      var   pop     mean    stat      SE   RSE    dif  pval   MOE
1: RENTAD 43953 44670.66 717.662 280.935 0.006 -0.016 0.011 0.012
2: RENTAB 56453 57110.42 657.421 395.954 0.007 -0.012 0.097 0.014
[1] "Implied Pop. size Reweighted:"
[1] 1301048
[1] "Summary of calibrated weights"
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  0.000   1.345   4.359  16.713  17.837 619.792

```

#--------------------------------------------------------------------------------------#

```r
    # Apply calibration with the new named vector
    subsample <- calibrate(
        design = pre_subsample,
        formula = ~ -1 + TIPOHOG + RENTAB,
        population = calibration_totals_vec,
        calfun = "linear",
        bounds = limits,
        bounds.const = TRUE,
        maxit = 2000
    )
```

## 1 STEP CALIBRATED 2016

---

```r
      var   pop     mean    stat      SE   RSE    dif  pval   MOE
1: RENTAD 39613 40075.37 462.373 262.422 0.007 -0.012 0.078 0.013
2: RENTAB 49831 49826.32  -4.677 348.893 0.007  0.000 0.989 0.014
[1] "Implied Pop. size Reweighted:"
[1] 1254513
[1] "Summary of calibrated weights"
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  1.111   2.216   6.705  25.484  33.077 575.512
```

##  1 STEP CALIBRATED 2021

```r
      var   pop     mean     stat      SE   RSE    dif  pval   MOE
1: RENTAD 43953 46373.09 2420.088 393.486 0.008 -0.055     0 0.017
2: RENTAB 56453 59046.65 2593.646 546.964 0.009 -0.046     0 0.018
[1] "Implied Pop. size Reweighted:"
[1] 1301048
[1] "Summary of calibrated weights"
    Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
  0.0018   1.1474   3.8811  16.7129  24.5950 600.7309
```

#--------------------------------------------------------------------------------------#

## UNCALIBRATED 2016

---

```r
      var   pop     mean    stat      SE   RSE    dif  pval   MOE
1: RENTAD 39613 40537.71 924.713 286.155 0.007 -0.023 0.001 0.014
2: RENTAB 49831 50683.07 852.066 381.496 0.008 -0.017 0.026 0.015
[1] "Implied Pop. size Reweighted:"
[1] 1254462
[1] "Summary of calibrated weights"
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
  1.111   2.847   6.400  25.483  31.442 575.520
```

## UNCALIBRATED 2021

```r
      var   pop     mean     stat      SE   RSE    dif  pval   MOE
1: RENTAD 43953 46373.09 2420.088 393.486 0.008 -0.055     0 0.017
2: RENTAB 56453 59046.65 2593.646 546.964 0.009 -0.046     0 0.018
[1] "Implied Pop. size Reweighted:"
[1] 1301048
[1] "Summary of calibrated weights"
    Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
  0.0018   1.1474   3.8811  16.7129  24.5950 600.7309
```

