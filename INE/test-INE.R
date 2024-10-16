rm(list = ls())
library(data.table)
library(magrittr)
library(survey)

dt <- fread("INE/ECH.2017.gz")

dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACCAL)
dt_sv <- subset(dt_sv, CA == 7 & IDQ_PV == 40 & TAMANO == 9)

tipos_hog <- svymean(~ as.factor(TIPOHO), dt_sv)
tipos_hog <- data.table(names(tipos_hog), tipos_hog) %>% print()
