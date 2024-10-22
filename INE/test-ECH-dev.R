rm(list = ls())
library(data.table)
library(magrittr)
library(survey)

# Load data
dt <- fread("INE/encuesta_continua_hogares_2017/ECH.2017.gz")
dt2 <- fread("AEAT/data/IDENHOG2016.gz")
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

dt2[, TIPOHOG2 := TIPOHOG][, TIPOHOG := 0][, TIPOHOG := fcase(
    TIPOHOG2 %in% "1.1.1", 1,
    TIPOHOG2 %in% "1.1.2", 2,
    TIPOHOG2 %in% "1.2", 3,
    TIPOHOG2 %in% "2.1.1", 4,
    TIPOHOG2 %in% "2.1.2", 5,
    TIPOHOG2 %in% "2.1.3", 6,
    TIPOHOG2 %in% c("2.2.1", "2.3.1"), 7,
    TIPOHOG2 %in% c("2.2.2", "2.3.2"), 8
)][, TIPOHOG := as.factor(TIPOHOG)]
dt2[, TRAMO2 := 0][, TRAMO2 := fcase(
    TRAMO %in% 0, 1,
    TRAMO %in% 1, 2,
    TRAMO %in% c(2, 3, 4, 5, 6, 7), 3,
    TRAMO %in% 8, 4
)][, TRAMO2 := as.factor(TRAMO2)]

dt_sv <- svydesign(~1, data = dt, weights = dt$FACCAL)
dt_sv2 <- svydesign(~1, data = dt2, weights = dt2$FACTORCAL)
# dt_sv <- subset(dt_sv, IDQ_PV == 28)
# dt_sv2 <- subset(dt_sv2, PROV == 28)

prop_hogs <- svytotal(~TIPOHOG, dt_sv) %>% data.table()
prop_hogs <- data.table(FREQ = prop.table(prop_hogs)[, 1], TOTAL = prop_hogs) %>% print()
sum(weights(dt_sv)) %>% print()

prop_hogs2 <- svytotal(~TIPOHOG, dt_sv2) %>% data.table()
prop_hogs2 <- data.table(FREQ = prop.table(prop_hogs2)[, 1], TOTAL = prop_hogs2) %>% print()
sum(weights(dt_sv2)) %>% print()

prop_tramo2 <- svytotal(~TRAMO2, dt_sv2) %>% data.table()
prop_tramo2 <- data.table(FREQ = prop.table(prop_tramo2)[, 1], TOTAL = prop_tramo2) %>% print()


summary(dt2$TRAMO2) / sum(summary(dt2$TRAMO2)) %>% print()
