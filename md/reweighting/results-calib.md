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

Afterwards, we get the following results

```r
## MADRID 2021: rake on TRAMO + TIPOHOG 1st and then calib on RENTAD (method raking)
|--------------------------------------------------|
|==================================================|
     pop     mean     stat      se.    dif  p-value
   <num>    <num>    <num>     <num>  <num>  <num>
1: 43953 44454.10  501.099   267.156 -0.011  0.061
2: 56453 56312.41 -140.591   371.188  0.002  0.705

[1] 1286382
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
  0.000   1.129   3.865  16.524  24.281 599.279

## MADRID 2016: rake on TRAMO + TIPOHOG 1st and then calib on RENTAD (method raking)
|--------------------------------------------------|
|==================================================|
     pop     mean     stat      se.    dif  p-value
   <num>    <num>    <num>     <num>  <num>  <num>
1: 39613 39737.09  124.089   250.699 -0.003  0.621
2: 49831 49597.09 -233.906   335.383  0.005  0.486

[1] 1250545
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
  0.007   2.846   6.397  25.403  31.301 575.250
```

As a result mean differences (represented by "stat") greatly diminished and, for a standard 95% confidence level, we could not reject the null hypothesis of the difference between the true population mean and our prediction being 0 (as reflected by "p-value" greater than 0.05 in all cases, both for RENTAD and RENTAB).