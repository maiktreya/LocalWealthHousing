# Procedure to reweight subsamples from AEAT from levels below CCAA

## Main script

Para realizar recalibración customizada de pesos y evaluar su robustez para realizar inferencia representativa sobre una unidad geográfica de nivel provincial disponemos del script `representativity.R` que permite un análisis unificado. Puede ejecutarse con `$HOME/AEAT/src/tests/representativity.R` asumiendo que `getwd() == $HOME`:

```{r}
source"$HOME/AEAT/src/tests/representativity.R", encoding = "UTF-8")
```

## Functions needed to reweight subsamples from AEAT from levels below CCAA

La función `get_wave`, que es utilizada por otros scripts para establecer tanto la población objetivo como el ejercicio de análisis.

- El parametro `city` representa la ciudad objetivo sobre la que se quieren recalcular los pesos muestrales con representatividad.
- El parametro `sel_year` refleja el año a analizar.
- El parametro `represet` permite elegir el universo de referencia, con opciones como la población total o los declarantes como unidad de referencia.
- El parametro `ref_unit` fija el nivel base de identificación (a elegir entre personas y hogares).
- El parametro `calibrate` (boolean) permite calibrar la encuesta reescalando para el ingreso bruto (RENTAB) como referencia.

- El parametro `rake` (logical) permite realizar "Iterative Proportional Fitting" (IPS) to adjust for known population proportions (age group and gender)

```{r}
# get a sample weighted for a given city
dt <- get_wave(
    city = city, # subregional unit
    sel_year = sel_year, # wave
    ref_unit = ref_unit, # reference PSU (either household or individual)
    represet = represet, # reference universe/population (whole pop. or tax payers)
    calibrated = TRUE, # Requieres auxiliary pop. data on mean RENTAD for the choosen city
    raked = rake_mode # Requieres auxiliary pop. age and sex frequencies for the choosen city
)

# define survey for the subsample of interest
subsample <- svydesign(
    ids = ~1,
    data = subset(dt, MUESTRA == city_index),
    weights = dt$FACTORCAL
)
```

Once our reweighted survey is available we run the following operations in order to test the robustness of our inference on key variables (income):

```{r}
# calculate sample means
RNmean <- svymean(~RENTAD, subsample)
RBmean <- svymean(~RENTAB, subsample)

# Test if the survey means are equal to the population means
test_rep1 <- svycontrast(RNmean, quote(RENTAD - RNpop)) %>% as.numeric()
test_rep2 <- svycontrast(RBmean, quote(RENTAB - RBpop)) %>% as.numeric()

# Calculate p-values using two-tailed test over t-statistics
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

```

Finalmente podemos mostrar los resultados para su análisis:

```{r}
# Combine and print the results
results <- rbind(net_vals, gross_vals, use.names = FALSE) %>%
    round(3) %>%
    print()

# Print sample sizes
sum(1 / subsample$variables[, "FACTORCAL"]) %>% print()
sum(subsample$variables[, "FACTORCAL"]) %>% print()


#### Results for 2016 calibrated on RENTAD not raked
|==================================================|
     pop     mean   stat se.RENTAD    dif p_value.RENTAD
   <num>    <num>  <num>     <num>  <num>          <num>
1: 39613 40072.83 459.83   265.109 -0.012          0.083   RENTAD
2: 49831 50076.93 245.93   354.593 -0.005          0.488   RENTAB
[1] 13576.06
[1] 1240068
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  1.111   2.842   6.390  25.190  30.864 574.437 


#### Results for 2021 calibrated on RENTAD not raked
|==================================================|
     pop     mean     stat se.RENTAD    dif p_value.RENTAD
   <num>    <num>    <num>     <num>  <num>          <num>
1: 43953 44370.26  417.262   262.413 -0.009          0.112  RENTAD
2: 56453 56184.57 -268.432   364.460  0.005          0.461  RENTAB
[1] 72688.25
[1] 1288813
    Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
  0.0018   1.1300   3.8677  16.5557  24.3365 599.5457 

```

Si los nuevos resultados son representativos, la diferencia entre el valor poblacional `pop` y nuestra media recalibrada `mean` debe ser pequeña al igual que la diferencia porcentual sobre el valor referencia `dif`.

Adicionalmente, el `p_value` asociado, para un intervalo del 95%, tiene que ser mayor que 0.05.

Si la recalibración iterativa fue efectiva, pueden aplicarse los mismos parametros de la función `get_wave` en el script principal para realizar el análisis de datos estadísticos estando seguro de su representatividad a la escala `city`.

```{r}
# RESULTS FOR FULLY SPECIFIED SVYDESIGN (RAKED = TRUE, CALIBRATED = FALSE)
|==================================================|    
     pop     mean     stat se.RENTAD    dif p_value.RENTAD
   <num>    <num>    <num>     <num>  <num>          <num>
1: 43953 47504.78 3551.777   390.163 -0.081              0
2: 56453 60247.65 3794.652   543.977 -0.067              0
[1] 46437.31
[1] 1307682
    Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
  0.0028   1.1520   3.4692  16.7981  18.9477 570.4690 

# RESULTS FOR MINIMALLY SPECIFIED SVYDESIGN (RAKED = TRUE, CALIBRATED = FALSE)
|--------------------------------------------------|
|==================================================|
     pop     mean     stat se.RENTAD    dif p_value.RENTAD
   <num>    <num>    <num>     <num>  <num>          <num>
1: 43953 47504.78 3551.777   390.163 -0.081              0
2: 56453 60247.65 3794.652   543.977 -0.067              0
[1] 46437.31
[1] 1307682
    Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
  0.0028   1.1520   3.4692  16.7981  18.9477 570.4690 

# RESULTS FOR FULLY SPECIFIED SVYDESIGN BOUND AND TRIMMED (RAKED = TRUE, CALIBRATED = FALSE)

```
