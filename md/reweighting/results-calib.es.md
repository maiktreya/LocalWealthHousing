
# Resultados de Calibraciones Alternativas

Para realizar una recalibración personalizada de los pesos y evaluar su robustez para inferencias representativas a nivel geográfico provincial o municipal, utilizamos el script `representativity.R`, que permite un análisis unificado. Puede ejecutarse con `$HOME/AEAT/src/tests/representativity.R` asumiendo que `getwd() == $HOME`:

```r
source("$HOME/AEAT/src/tests/representativity.R", encoding = "UTF-8")
```

## Funciones Necesarias para Reponderar Submuestras de AEAT para Niveles Inferiores a CCAA

La función `get_wave` es utilizada por otros scripts para establecer tanto la población objetivo como el contexto de análisis.

- El parámetro `city` especifica la ciudad objetivo para recalcular los pesos de la muestra para representatividad.
- El parámetro `sel_year` indica el año a analizar.
- El parámetro `represet` permite elegir el universo de referencia, con opciones como la población total o los declarantes de impuestos como unidad de referencia.
- El parámetro `ref_unit` establece el nivel base de identificación (elige entre individuos y hogares).
- El parámetro `calibrate` (booleano) permite la calibración de la encuesta ajustando contra variables categóricas (TIPOHOG) y variables continuas (RENTAB y RENTAD) para las cuales se conocen los totales de población.

```r
# Obtener una muestra ponderada para una ciudad específica
dt <- get_wave(
    city = city, # Unidad subregional
    sel_year = sel_year, # Año de la ola
    ref_unit = ref_unit, # PSU de referencia (ya sea hogar o individuo)
    represet = represet, # Universo/población de referencia (población total o contribuyentes)
    calibrated = TRUE, # Requiere datos auxiliares de población sobre la media de RENTAD para la ciudad elegida
)

# Integrar la estructura AEAT en svydesign
dt_sv <- svydesign(
    ids = ~IDENHOG, # Identificador del hogar para la PSU base
    strata = ~ CCAA + TIPOHOG + TRAMO, # Región, tipo de hogar y cuantil de ingresos
    data = dt, # matriz previamente preparada con las observaciones individuales de las variables de interes
    weights = dt$FACTORCAL, # Pesos muestrales originales (rep. a nivel CCAA)
    nest = TRUE # Los hogares están anidados dentro de IDENPER y múltiples REFCAT
)
```

Una vez que nuestra encuesta está disponible, realizamos las siguientes operaciones para probar la robustez de nuestra inferencia en variables clave (ingreso):

```r
# Calcular las medias de la muestra
RNmean <- svymean(~RENTAD, subsample)
RBmean <- svymean(~RENTAB, subsample)

# Probar si las medias de la encuesta son iguales a las medias de la población
test_rep1 <- svycontrast(RNmean, quote(RENTAD - RNpop)) %>% as.numeric()
test_rep2 <- svycontrast(RBmean, quote(RENTAB - RBpop)) %>% as.numeric()

# Calcular valores p usando una prueba de dos colas sobre estadísticos t
p_val1 <- 2 * (1 - pnorm(abs(test_rep1 / SE(RNmean))))
p_val2 <- 2 * (1 - pnorm(abs(test_rep2 / SE(RBmean))))

# Preparar la tabla de resultados con valores p
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

# Combinar e imprimir los resultados
results <- rbind(net_vals, gross_vals, use.names = FALSE) %>%
    round(3) %>%
    print()

# Imprimir tamaños de muestra
sum(1 / subsample$variables[, "FACTORCAL"]) %>% print()
sum(subsample$variables[, "FACTORCAL"]) %>% print()
```

## Estadísticas Brutas No Calibradas

"FACTORCAL" está ajustado para el nivel CCAA, así que sin otros ajustes, nuestra submuestra conduce a resultados sesgados:

```r
## MADRID 2021: sin calibración o raking
|--------------------------------------------------|
|==================================================|
     pop     mean     stat      se.    dif  p-value
   <num>    <num>    <num>     <num>  <num>  <num>
1: 43953 46373.09 2420.088   393.486 -0.055  0.000
2: 56453 59046.65 2593.646   546.964 -0.046  0.000
[1] 1301048
    Min.  1st Qu.   Median     Mean  3rd Qu.     Max.
  0.0018   1.1474   3.8811  16.7129  24.5950 600.7309


  ## MADRID 2016: sin calibración o raking
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

## Estadísticas Calibradas Iterativamente en Proporciones y Totales

Para lograr representatividad a nivel de ciudad, necesitamos ajustar los pesos de la muestra. Usando el paquete survey de R, el proceso implica utilizar `calibrate` después de definir nuestro objeto inicial `svydesign` basado en la estructura del panel AEAT.

Realizamos el ajuste teniendo en cuenta la estructura poblacional de 1/3 de las variables de estratificación a través de TIPOHOG (10 tipos de hogar).

Las otras dos no son útiles para este nivel de submuestra (CCAA) o son desconocidas para la unidad regional dada (TRAMO para frecuencias de 9 cuantiles de ingresos). Sin embargo, dado que este procedimiento de calibración permite tanto variables categóricas como continuas, incluimos también el monto total conocido de ingresos brutos (RENTAB) y netos (RENTAD).

En código R:

```r
# Preparar el objeto de encuesta
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

# Aplicar calibración con el vector nombrado
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

Las estadísticas actualizadas resultantes son las siguientes:

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
[1] "Implied Pop. size original:"
[1] 1307682
[1] "Implied Pop. size Reweighted:"
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
[1] "Implied Pop. size original:"
[1] 1254513
[1] "Sample size Reweighted:"
[1] 1254513
[1] "Implied Pop. size weights"
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
  1.111   2.253   6.920  25.484  32.906 575.520
```

Como resultado, las diferencias de medias (representadas por "stat") entre los valores reales (pop) y estimados (mean) se reducen considerablemente. Para un nivel de confianza estándar del 95%, no podemos rechazar la hipótesis nula de que la diferencia entre la media verdadera de la población y nuestra estimación es cero (como se muestra en los valores p mayores a 0.05 para tanto RENTAD como RENTAB).
