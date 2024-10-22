rm(list = ls())
library(data.table)
library(magrittr)
library(survey)

# Load data
dt <- fread("INE/encuesta_continua_hogares_2017/ECH.2017.gz")
codes <- fread("AEAT/data/base_hogar/codes-typehog.ECH.csv")

dt[, TIPOHOG := 0][, TIPOHOG := fcase(
    TIPOHO %in% 1, 1,
    TIPOHO %in% 2, 2,
    TIPOHO %in% c(3, 4), 3,
    TIPOHO %in% c(6, 8, 10, 11) & NHIJOMENOR == 1, 4,
    TIPOHO %in% c(6, 8, 10, 11) & NHIJOMENOR == 2, 5,
    TIPOHO %in% c(6, 8, 10, 11) & NHIJOMENOR >= 3, 6,
    TIPOHO %in% c(5, 15) & TAMTOHO == 2, 7,
    TIPOHO %in% c(7, 9, 12, 13, 14, 15, 16) & TAMTOHO > 2, 8
)][, TIPOHOG := as.factor(TIPOHOG)]

dt_sv <- svydesign(~1, data = dt, weights = dt$FACCAL)

prop_hogs <- svytable( ~ TIPOHOG, dt_sv)
prop_hogs <- data.table(prop.table(prop_hogs), prop_hogs) %>% print()