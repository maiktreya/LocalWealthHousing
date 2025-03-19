# Clear the workspace (consider removing this in production)
rm(list = ls())

# Load necessary libraries
library(data.table)
library(survey)
library(magrittr)

# Import original households and persons base files
dt_hog <- fread("AEAT/data/ine/ECHHogares_2016.csv")
dt_per <- fread("AEAT/data/ine/ECHPersonas_2016.csv")
tipos_cat <- fread("AEAT/data/tipohog-madrid-2016.csv")[, .(Desc, Tipohog, index)]

# Merge files and rename columns for clarity
dt <- merge(dt_per, dt_hog, by = c("ID_VIV", "FACCAL", "IDQ_PV", "CA", "TAMANO"))
setnames(dt,
    old = c(
        "EDAD", "ID_VIV", "TAMTOHO", "FACCAL", "IDQ_PV", "CA",
        "NHIJO", "NHIJOMENOR", "TIPOHO", "TAMANO"
    ),
    new = c(
        "EDAD", "IDEN", "TAMTOHO", "FACTOR", "IDQ_PV", "IDQ_MUN",
        "HIJOS", "HIJOS_MENORES", "TIPOHOGAR", "TAM_MUNI"
    )
)

# Generate control dummies
dt[, adul_65 := fifelse(EDAD >= 65, 1, 0)]
dt[, adul := fifelse(EDAD >= 18, 1, 0)]
dt[, TAM_MUNI := as.numeric(TAM_MUNI)]

# Group persons by households
dt <- dt[, .(
    MEMBERS_ALT = uniqueN(NPV),
    MEMBERS = mean(TAMTOHO, na.rm = TRUE),
    FACTOR = mean(FACTOR, na.rm = TRUE),
    IDQ_PV = mean(IDQ_PV, na.rm = TRUE),
    IDQ_MUN = mean(IDQ_MUN, na.rm = TRUE),
    EDAD = first(EDAD), # Ensure order is appropriate
    HIJOS_MENORES = first(HIJOS_MENORES),
    HIJOS = first(HIJOS),
    TIPOHOGAR = first(TIPOHOGAR),
    REGVI = first(REGVI),
    TAM_MUNI = first(TAM_MUNI),
    NADUL65 = sum(adul_65, na.rm = TRUE),
    NADUL = sum(adul, na.rm = TRUE)
), by = IDEN]

# Group households by type
dt[, TIPOHOG := fcase(
    MEMBERS == 1 & NADUL65 != 0, 1,
    MEMBERS == 1 & NADUL65 == 0, 2,
    MEMBERS > 1 & NADUL == 1, 3,
    NADUL >= 2 & HIJOS_MENORES == 1, 4,

    NADUL >= 2 & HIJOS_MENORES == 2, 5,
    NADUL >= 2 & HIJOS_MENORES >= 3, 6,
    NADUL >= 2 & HIJOS_MENORES == 0 & NADUL65 != 0 & MEMBERS == 2, 7,
    NADUL >= 2 & HIJOS_MENORES == 0 & NADUL65 != 0 & MEMBERS > 2, 8,
    MEMBERS > 2, 10,
    MEMBERS == 2, 9,
    default = NA # Clear default case
)][, TIPOHOG := as.factor(TIPOHOG)]

# Define weights and create survey object
dt_sv <- svydesign(
    ~1,
    data = dt,
    weights = dt$FACTOR
) %>% subset(IDQ_PV == "40" & TAM_MUNI == "9")

# Calculate proportion of households by type
prop_hogs <- svytotal(~TIPOHOG, dt_sv) %>% data.table()
regvi_pri <- svytable(~ as.factor(REGVI), dt_sv) %>% prop.table()
regvi_pri <- c(prop = sum(regvi_pri[1:2]), alq = regvi_pri[3], otr = regvi_pri[4])

# Calculate frequencies and total
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

# fwrite(prop_hogs, "AEAT/data/tipohog-segovia-2016.csv")




tabla <- svyby(~TIPOHOG, ~REGVI, dt_sv, svytotal, keep.var = FALSE ) %>% prop.table() %>% data.table()



dt[,HOGUNI := fifelse(TIPOHOG == 3, "uni", "no_uni")]


dt_sv$variables[,"HOGUNI"] <- dt$HOGUNI

tabla <- svyby(~REGVI, ~HOGUNI, dt_sv, svytotal, keep.var = FALSE ) %>% prop.table() 


svytotal(~HOGUNI, )