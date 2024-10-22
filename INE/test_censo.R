rm(list = ls())
gc()
library(data.table)
library(magrittr)
library(survey)

dt <- load("CensoPersonas_2021/R/CensoPersonas_2021.RData")
