# Resultados de calibraciones alternativas

Para realizar una recalibración personalizada de los pesos y evaluar su robustez para la inferencia representativa sobre una unidad geográfica a nivel provincial, utilizamos el script `representativity.R`, que permite un análisis unificado. Puede ejecutarse con `$HOME/AEAT/src/tests/representativity.R` asumiendo que `getwd() == $HOME`:

```r
source("$HOME/AEAT/src/tests/representativity.R", encoding = "UTF-8")
```

## Funciones necesarias para reponderar submuestras de AEAT por debajo del nivel de CCAA

La función `get_wave` es utilizada por otros scripts para establecer tanto la población objetivo como el contexto de análisis.

- El parámetro `city` especifica la ciudad objetivo para recalcular los pesos muestrales con representatividad.
- El parámetro `sel_year` indica el año a analizar.
- El parámetro `represet` permite elegir el universo de referencia, con opciones como la población total o los declarantes de impuestos.
- El parámetro `ref_unit` define el nivel base de identificación (a elegir entre individuos y hogares).
- El parámetro `calibrate` (booleano) permite calibrar la encuesta reescalando sobre variables categóricas (TIPOHOG) y continuas (RENTAB y RENTAD) cuyos totales poblacionales son conocidos.

```r
# Obtener una muestra ponderada para una ciudad específica
dt <- get_wave(
    city = city, # Unidad subregional
    sel_year = sel_year, # Ola de análisis
    ref_unit = ref_unit, # Unidad primaria de muestreo (hogar o individuo)
    represet = represet, # Universo/población de referencia (total o declarantes de impuestos)
    calibrated = TRUE, # Requiere datos auxiliares poblacionales sobre la renta media (RENTAD) para la ciudad elegida
    raked = rake_mode # Requiere frecuencias auxiliares de edad y sexo para la ciudad elegida
)

# Definir la encuesta para la submuestra de interés
subsample <- svydesign(
    ids = ~1,
    data = subset(dt, MUESTRA == city_index),
    weights = dt$FACTORCAL
)
```

Una vez que nuestra encuesta reponderada está disponible, realizamos las siguientes operaciones para probar la robustez de nuestra inferencia en variables clave (renta):

```r
# Calcular las medias muestrales
RNmean <- svymean(~RENTAD, subsample)
RBmean <- svymean(~RENTAB, subsample)

# Probar si las medias muestrales son iguales a las medias poblacionales
test_rep1 <- svycontrast(RNmean, quote(RENTAD - RNpop)) %>% as.numeric()
test_rep2 <- svycontrast(RBmean, quote(RENTAB - RBpop)) %>% as.numeric()

# Calcular los p-valores usando una prueba bilateral sobre estadísticas t
p_val1 <- 2 * (1 - pnorm(abs(test_rep1 / SE(RNmean))))
p_val2 <- 2 * (1 - pnorm(abs(test_rep2 / SE(RBmean))))

# Preparar la tabla de resultados con los p-valores
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

# Imprimir los tamaños de muestra
sum(1 / subsample$variables[, "FACTORCAL"]) %>% print()
sum(subsample$variables[, "FACTORCAL"]) %>% print()
```

## Estadísticas brutas sin calibrar

Para lograr representatividad a nivel de ciudad, es necesario ajustar los pesos muestrales. El ajuste adecuado, dado el panel de AEAT:

```r
# Integrar la estructura de AEAT en svydesign
dt_sv <- svydesign(
    ids = ~IDENHOG, # Identificador del hogar como unidad primaria de muestreo
    strata = ~ CCAA + TIPOHOG + TRAMO, # Comunidad autónoma, tipo de hogar y cuantil de ingresos
    data = dt,
    weights = dt$FACTORCAL,
    nest = TRUE # Los hogares están anidados dentro de IDENPER y múltiples REFCAT
)
```

Es necesario ajustar el "FACTORCAL" a nivel de CCAA para evitar sesgos en las estimaciones de variables clave, como se muestra en este ejemplo de la ciudad de Madrid:

```r
## MADRID 2021: Sin raking o calibración
|--------------------------------------------------|
|==================================================|
     pop     mean     stat      se.    dif  p-value
   <num>    <num>    <num>     <num>  <num>  <num>
1: 43953 46373.09 2420.088   393.486 -0.055  0.000
2: 56453 59046.65 2593.646   546.964 -0.046  0.000
[1] 1301048
   Min. 1st Qu.   Mediana     Media  3rd Qu.     Max.
 0.0018   1.1474   3.8811  16.7129  24.5950 600.7309
```

## Estadísticas calibradas iterativamente sobre proporciones y totales

Debemos aplicar un procedimiento en 2 pasos para mejorar los pesos sobre el objeto inicial (`dt_sv`):

1. **Paso 1**: Reponderar mediante ajuste proporcional iterativo (IPS) sobre los datos de estratos.
2. **Paso 2**: Calibrar sobre el ingreso total conocido (RENTAD).

Usando el paquete survey de R, el proceso implica usar `calibrate` después de definir nuestro objeto inicial `svydesign`:

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

Los resultados actualizados obtenidos son los siguientes:

```r
## MADRID 2021: Calibrado
|--------------------------------------------------|
|==================================================|
     pop     mean     stat      se.    dif  p-value
   <num>    <num>    <num>     <num>  <num>  <num>
1: 43953 43730.03 -222.972 654.210 0.005   0.733
2: 56453 56166.62 -286.384 359.646 0.005   0.426
[1] "Tamaño de la población implícita original:" 1307682
[1] "Tamaño de la población implícita reponderada:" 1307682
[1] "Resumen de pesos calibrados"
   Min. 1st Qu.   Mediana     Media  3rd Qu.     Max.
 0.0018   1.1541   3.5063  16.7981  18.6821 581.8978
```

Como resultado, las diferencias medias (representadas por "stat") disminuyen notablemente. Para un nivel de confianza estándar del 95%, no podemos rechazar la hipótesis nula de que la diferencia entre la media poblacional verdadera y nuestra estimación sea cero (como se refleja en los p-valores mayores a 0.05 en todos los casos, tanto para RENTAD como para RENTAB).