# BASE RENTHOG CATEGORIES + LINEAR CALIB (RENTAB)

#--------------------------------------------------------------------------------------#

---

## NO CALIBRATION 2016

---

```r
     var   pop     mean     stat       SE   RSE    dif  pval   MOE
1: RENTAD 30203 31327.17 1124.168 1173.057 0.037 -0.037 0.338 0.073
2: RENTAB 35772 37273.46 1501.464 1506.509 0.040 -0.042 0.319 0.079
[1] "Implied Pop. size Reweighted:"
[1] 18792.28
[1] "Summary of calibrated weights"
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  1.097   2.918   8.738  22.452  25.875 485.420 
```

---

## NO CALIBRATION

---

```r
      var   pop     mean    stat       SE   RSE    dif  pval   MOE
1: RENTAD 34272 34593.02 321.021 1136.886 0.033 -0.009 0.778 0.064
2: RENTAB 41235 41763.19 528.189 1488.342 0.036 -0.013 0.723 0.070
[1] "Implied Pop. size Reweighted:"
[1] 19236.38
[1] "Summary of calibrated weights"
    Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
  0.1428   1.8405   6.2870  17.8115  24.7028 189.1128
```



## REDUCED BOUNDED LINEAR 2021

```r
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

```r
      var   pop     mean    stat       SE   RSE    dif  pval   MOE
1: RENTAD 34272 34388.79 116.790 1068.487 0.031 -0.003 0.913 0.061
2: RENTAB 41235 41584.82 349.821 1396.498 0.034 -0.008 0.802 0.066
[1] "Implied Pop. size Reweighted:"
[1] 21034
[1] "Summary of calibrated weights"
    Min.  1st Qu.   Median     Mean  3rd Qu.     Max.
  0.1594   2.0303   8.0223  19.4759  22.7381 186.3632
```



## REDUCED BOUNDED LINEAR 2016

---

```r
      var   pop     mean    stat       SE   RSE    dif  pval   MOE
1: RENTAD 30203 30373.83 170.827 1312.863 0.043 -0.006 0.896 0.085
2: RENTAB 35772 36167.92 395.919 1687.409 0.047 -0.011 0.814 0.091
[1] "Implied Pop. size Reweighted:"
[1] 19280.31
[1] "Summary of calibrated weights"
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
  1.127   4.458   8.590  23.035  26.476 490.915
```

