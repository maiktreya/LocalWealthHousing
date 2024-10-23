rm(list = ls())
library(data.table)
library(magrittr)
library(survey)

# Import original sample
dt <- fread("AEAT/data/ine/ECEPOVhogar_2021.csv")
tipos_cat <- fread("AEAT/data/tipohog-madrid-2021.csv")[, .(Desc, Tipohog, index)]

# Generate control dummies
dt[, adul_65 := 0][SITUHOGAR != 5 & EDAD >= 65, adul_65 := 1]
dt[, adul := 0][EDAD >= 18, adul := 1]
dt[, TIPONUCLEO := as.numeric(TIPONUCLEO)]

# group persons by households
dt <- dt[, .(
    MEMBERS_ALT = uniqueN(NPV),
    MEMBERS = max(NPV),
    FACTOR = mean(FACTOR),
    IDQ_PV = mean(IDQ_PV),
    IDQ_MUN = mean(IDQ_MUN), # SEGOVIA 40194
    EDAD = first(EDAD),
    HIJOS_NUCLEO_MENORES = first(HIJOS_NUCLEO_MENORES),
    HIJOS_NUCLEO = first(HIJOS_NUCLEO),
    TIPOHOGAR = first(TIPOHOGAR),
    TIPONUCLEO = first(TIPONUCLEO),
    SITUHOGAR = first(SITUHOGAR),
    TAM_MUNI = first(TAM_MUNI),
    NADUL65 = sum(adul_65),
    NADUL = sum(adul)
),
by = IDEN
]

# group households by type
dt[, TIPOHOG := 0][, TIPOHOG := fcase(
    MEMBERS == 1  & NADUL65 != 0, 1,
    MEMBERS == 1  & NADUL65 == 0, 2,
    MEMBERS > 1 & NADUL == 1, 3,
    NADUL >= 2 & HIJOS_NUCLEO_MENORES == 1, 4,
    NADUL >= 2 & HIJOS_NUCLEO_MENORES == 2, 5,
    NADUL >= 2 & HIJOS_NUCLEO_MENORES >= 3, 6,
    NADUL >= 2 & HIJOS_NUCLEO_MENORES == 0 & NADUL65 != 0 & MEMBERS == 2, 7,
    NADUL >= 2 & HIJOS_NUCLEO_MENORES == 0 & NADUL65 != 0 & MEMBERS > 2, 8,
    TIPOHOG == 0 & MEMBERS > 2, 10,
    TIPOHOG == 0 & MEMBERS == 2, 9
)][, TIPOHOG := as.factor(TIPOHOG)]

# define weights and survey object
dt_sv <- svydesign(
    ~1,
    data = dt,
    weights = dt$FACTOR
) %>% subset(IDQ_MUN == 40194)

# calculate proportion of households by type
prop_hogs <- svytotal(
    ~TIPOHOG,
    dt_sv
) %>% data.table()

prop_hogs <- data.table(
    FREQ = prop.table(prop_hogs)[, 1],
    TOTAL = prop_hogs
)
prop_hogs <- cbind(tipos_cat, prop_hogs)
colnames(prop_hogs) <- c("Desc", "Tipohog", "index", "Freq.", "Total")

# Validate results
print(prop_hogs)
total_freq <- sum(prop_hogs[, Freq.]) %>% print()
weight_difference <- sum(weights(dt_sv)) - sum(prop_hogs[, Total]) %>% print()

fwrite(prop_hogs, "AEAT/data/tipohog-segovia-2021.csv")
