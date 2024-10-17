rm(list = ls())
library(data.table)
library(magrittr)
library(survey)

# Load data
dt <- fread("INE/encuesta_continua_hogares_2017/ECH.2017.gz")
codes <- fread("AEAT/data/base_hogar/codes-typehog.ECH.csv")

# Vectorized join to add the TIPOHO_DESC column
dt <- merge(dt, codes, by.x = "TIPOHO", by.y = "code", all.x = TRUE)
setnames(dt, "name", "TIPOHO_DESC") # Renaming the 'name' column to 'TIPOHO_DESC'

# Survey design and subsetting
dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACCAL)
dt_sv <- subset(dt_sv, CA == 7 & IDQ_PV == 40 & TAMANO == 9)

# Calculating mean proportions of household types
tipos_hog <- svymean(~ as.factor(TIPOHO_DESC), dt_sv)
tipos_hog <- data.table(names(tipos_hog), tipos_hog) %>% print()

dt <- dt_sv$variables
dt[, FACCAL := weights(dt_sv)]


# categorias de hogar ajustadas a tipos panel AEAT

dt[TIPOHO == 1, TIPOHOGAR_AEAT := "uniparental_menos65"]
dt[TIPOHO == 2, TIPOHOGAR_AEAT := "uniparental_mas65"]
dt[TIPOHO %in% c(3, 4), TIPOHOGAR_AEAT := "un_solo_adulto"]
dt[TAMTOHO == 4]
dt[TIPOHO %in% c(12), TIPOHOGAR_AEAT := "dos_adultos"]
dt[TIPOHO %in% c(5, 13, 15), TIPOHOGAR_AEAT := "dos_adultos"]


# 1.1.1 Hogar unipersonal -65
# 1.1.2 Hogar unipersonal +65
# 1.1.3 Hogar con un solo adulto
# 2.1.1 2+ Adultos y 1 menor
# 2.1.2 2+ Adultos y 2 menor
# 2.1.3 2+ Adultos y 3+ menor
# 2.2.1 2adultos (sin menores y alguno +65)
# 2.2.1 3+ adultos (sin menores y alguno +65)
# 2.3.1 2 adultos
# 2.3.2 3+ adultos


# 3	Madre/padre solo con algún hijo menor de 25 años
# 4	Madre/padre solo con algún hijo todos mayores de 24 años
# 6	Pareja con hijos de ambos miembros que conviven en el hogar alguno menor de 25 años
# 7	Pareja con hijos de ambos miembros que conviven en el hogar todos mayores de 24 años
# 10	Pareja con algún hijo menor de 25 años y otras personas
# 12	Pareja o Madre/padre con algún hijo todos mayores de 24 años y otras personas.

# 16	Otros (más de un núcleo)


# 1	Persona sola menor de 65 años
# 2	Persona sola de 65 años o más
# 13	Pareja sin hijos y otros familiares
# 15	Personas que no forman pareja y si tienen parentesco es distinto de padre e hijo
# 5	Pareja sin hijos que convivan en el hogar
