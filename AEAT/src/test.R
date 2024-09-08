# rscript resampling segovia
library("magrittr")
library("data.table")
library("survey")
iden21 <- fread("AEAT/data/ief2021/iden.gz")
par150 <- fread("AEAT/data/ief2021/par150.gz")
pat <- fread("AEAT/data/ief2021/pat.gz")
renta <- fread("AEAT/data/ief2021/renta.gz")
tipodec <- fread("AEAT/data/ief2021/tipodec.gz")

# codificacion 07 40 194 || segovia || CCAA / Provincia / Municipio

# Example auxiliary data for "CityX"
city_population <- 100000  # Replace with actual population value
city_income <- 30000  # Average income for the city
