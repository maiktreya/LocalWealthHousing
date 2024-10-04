# Procedure to reweight subsamples from AEAT from levels below CCAA


## Main script






## Functions needed to reweight subsamples from AEAT from levels below CCAA

La función `get_wave`, que es utilizada por otros scripts para establecer tanto la población objetivo como el ejercicio de análisis.

- El parametro `city` representa la ciudad objetivo sobre la que se quieren recalcular los pesos muestrales con representatividad.
- El parametro `sel_year` refleja el año a analizar.
- El parametro `represet` permite elegir el universo de referencia, con opciones como la población total o los declarantes como unidad de referencia.
- El parametro `ref_unit` fija el nivel base de identificación (a elegir entre personas y hogares).
- El parametro `calibrate` (boolean) permite calibrar la encuesta reescalando para el ingreso bruto (RENTAB) como referencia.

- El parametro `rake` (boolean) permite realizar "Iterative Proportional Fitting" (IPS) to adjust for known population proportions (age group and gender)

```{r}
city <- "madrid"
represet <- "!is.na(FACTORCAL)" # población
sel_year <- 2021
ref_unit <- "IDENHOG"

# get subsample
dt <- get_wave(
    city = city,
    sel_year = sel_year,
    ref_unit = ref_unit,
    represet = represet,
    calibrated = TRUE,
    raked = TRUE # Working just for Madrid & Segovia cities
)
```

```{r}
```