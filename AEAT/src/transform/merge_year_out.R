# clean enviroment and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)

dt1 <- fread("AEAT/out/segovia/segovia-2016-IDENHOGtabla-renta.csv")[, wave := 2016]
dt2 <- fread("AEAT/out/segovia/segovia-2021-IDENHOGtabla-renta.csv")[, wave := 2021]

dt <- rbind(dt1, dt2)

fwrite(dt, "AEAT/out/segovia/final/segovia-tabla-renta.csv")
