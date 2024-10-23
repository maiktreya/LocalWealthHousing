# Clear the workspace (consider removing this in production)
# rm(list = ls())

# Load necessary libraries
library(data.table)
library(survey)

# Import original households and persons base files
dt_hog <- fread("ECEH-2021/ECHHogares_2016.csv")
dt_per <- fread("ECEH-2021/ECHPersonas_2016.csv")

# Merge files and rename columns for clarity
dt <- merge(dt_per, dt_hog, by = c("ID_VIV", "FACCAL", "IDQ_PV", "CA", "TAMANO"))
setnames(dt,
         old = c("EDAD", "ID_VIV", "TAMTOHO", "FACCAL", "IDQ_PV", "CA",
                  "NHIJO", "NHIJOMENOR", "TIPOHO", "TAMANO"),
         new = c("EDAD", "IDEN", "TAMTOHO", "FACTOR", "IDQ_PV", "IDQ_MUN",
                  "HIJOS_NUCLEO", "HIJOS_NUCLEO_MENORES", "TIPOHOGAR", "TAM_MUNI"))

# Generate control dummies
dt[, adul_65 := fifelse(EDAD >= 65, 1, 0)]
dt[, adul := fifelse(EDAD >= 18, 1, 0)]
dt[, TAM_MUNI := as.numeric(TAM_MUNI)]

# Group persons by households
dt <- dt[, .(
    IDEN = mean(IDEN, na.rm = TRUE),
    MEMBERS_ALT = uniqueN(NPV),
    MEMBERS = mean(TAMTOHO, na.rm = TRUE),
    FACTOR = mean(FACTOR, na.rm = TRUE),
    IDQ_PV = mean(IDQ_PV, na.rm = TRUE),
    IDQ_MUN = mean(IDQ_MUN, na.rm = TRUE),
    EDAD = first(EDAD),  # Ensure order is appropriate
    HIJOS_NUCLEO_MENORES = first(HIJOS_NUCLEO_MENORES),
    HIJOS_NUCLEO = first(HIJOS_NUCLEO),
    TIPOHOGAR = first(TIPOHOGAR),
    TAM_MUNI = first(TAM_MUNI),
    NADUL65 = sum(adul_65, na.rm = TRUE),
    NADUL = sum(adul, na.rm = TRUE)
), by = IDEN]

# Replace NA values with a more appropriate method if needed (e.g., imputation)
dt[is.na(dt)] <- 0

# Group households by type
dt[, TIPOHOG := fcase(
    MEMBERS == 1 & NADUL == 1 & NADUL65 != 0, 1,
    MEMBERS == 1 & NADUL == 1 & NADUL65 == 0, 2,
    MEMBERS > 1 & NADUL == 1, 3,
    NADUL >= 2 & HIJOS_NUCLEO_MENORES == 1, 4,
    NADUL >= 2 & HIJOS_NUCLEO_MENORES == 2, 5,
    NADUL >= 2 & HIJOS_NUCLEO_MENORES >= 3, 6,
    NADUL >= 2 & HIJOS_NUCLEO_MENORES == 0 & NADUL65 != 0 & MEMBERS == 2, 7,
    NADUL >= 2 & HIJOS_NUCLEO_MENORES == 0 & NADUL65 != 0 & MEMBERS > 2, 8,
    MEMBERS > 2, 10,
    MEMBERS == 2, 9,
    default = 0  # Clear default case
)]
dt[, TIPOHOG := as.factor(TIPOHOG)]

# Define weights and create survey object
dt_sv <- svydesign(
    ~1,
    data = dt,
    weights = dt$FACTOR
) %>% subset(IDQ_PV == "40" & TAM_MUNI == "9")

# Calculate proportion of households by type
prop_hogs <- svytotal(~TIPOHOG, dt_sv) %>% data.table()

# Calculate frequencies and total
prop_hogs <- data.table(
    FREQ = prop.table(prop_hogs)[, 1],
    TOTAL = prop_hogs
) %>% print()

# Validate results
total_freq <- sum(prop_hogs[, FREQ]) %>% print()
weight_difference <- sum(weights(dt_sv)) - sum(prop_hogs[, TOTAL..]) %>% print()

# Consider adding checks for data integrity
if (weight_difference != 0) {
    warning("Weight discrepancy detected!")
}
