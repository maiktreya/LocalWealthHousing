# clean enviroment and import dependencies
rm(list = ls())
gc(full = TRUE, verbose = TRUE)
library(data.table)
library(survey)
library(magrittr)
# dt <- fread("AEAT/data/CensoPersonas_2021.gz")
load("CensoPersonas_2021/R/CensoPersonas_2021.RData")

dt <- data.table(Metadatos)

fwrite(dt, "AEAT/data/CensoPersonas_2021_metadatos.csv")