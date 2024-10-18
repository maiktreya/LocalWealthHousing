library(data.table)

# Define the categories for better understanding
type1_categories <- c(
  "Hogar unipersonal -65",
  "Hogar unipersonal +65",
  "Hogar con un solo +18",
  "2+ Adultos y 1 menor",
  "2+ Adultos y 2 menor",
  "2+ Adultos y 3+ menor",
  "2 adultos (sin menores y alguno +65)",
  "3+ adultos (sin menores y alguno +65)",
  "2 adultos",
  "3+ adultos"
)

type2_categories <- c(
  "Hogar con una mujer sola menor de 65 años",
  "Hogar con un hombre solo menor de 65 años",
  "Hogar con una mujer sola de 65 años o más",
  "Hogar con un hombre solo de 65 años o más",
  "Hogar con un solo progenitor que convive con algún hijo menor de 25 años",
  "Hogar con un solo progenitor que convive con todos sus hijos de 25 años o más",
  "Hogar formado por pareja sin hijos",
  "Otro tipo de hogar",
  "Hogar formado por pareja con hijos en donde algún hijo es menor de 25 años",
  "Hogar formado por pareja con hijos en donde todos los hijos de 25 años o más",
  "Hogar formado por pareja o un solo progenitor que convive con algún hijo menor de 25 años y otra(s) persona(s)"
)

type3_categories <- c(
  "Persona sola menor de 65 años",
  "Persona sola de 65 años o más",
  "Madre/padre solo con algún hijo menor de 25 años",
  "Madre/padre solo con algún hijo todos mayores de 24 años",
  "Pareja sin hijos que convivan en el hogar",
  "Pareja con hijos de ambos miembros que conviven en el hogar alguno menor de 25 años",
  "Pareja con hijos de ambos miembros que conviven en el hogar todos mayores de 24 años",
  "Pareja con algún hijo de un solo miembro y además alguno de los hijos menor de 25 años",
  "Pareja con algún hijo de un solo miembro que conviven en el hogar todos mayores de 25 años",
  "Pareja con algún hijo menor de 25 años y otras personas",
  "Madre/padre con algún hijo menor de 25 años y otras personas",
  "Pareja o Madre/padre con algún hijo todos mayores de 24 años y otras personas",
  "Pareja sin hijos y otros familiares",
  "Pareja sin hijos y otras personas alguna de ellas no tiene relación de parentesco con la pareja",
  "Personas que no forman pareja y si tienen parentesco es distinto de padre e hijo",
  "Otros (más de un núcleo)"
)

# Define the base data.table object with sample data
dt <- data.table(
  TYPE1 = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
  TYPE2 = c(1, 3, 5, 9, 7, 2, 4, 8, 10, 11),
  TYPE3 = c(1, 2, 3, 6, 5, 8, 7, 9, 15, 10)
)

# Assuming dt is your data.table containing the data with columns TYPE1, TYPE2, and TYPE3.
# Here, we'll create mappings for TYPE1 and TYPE3 to approximate TYPE2 as closely as possible.

# Define a helper function to map TYPE1 and TYPE3 classifications to TYPE2
map_types <- function(dt) {
  # Define TYPE1 to TYPE2 mapping
  dt[, TYPE2_from_TYPE1 := fcase(
    TYPE1 %in% c(1), 1, # "Hogar unipersonal -65" -> "Hogar con una mujer sola menor de 65 años"
    TYPE1 %in% c(2), 3, # "Hogar unipersonal +65" -> "Hogar con una mujer sola de 65 años o más"
    TYPE1 == 3, 5, # "Hogar con un solo +18" -> "Hogar con un solo progenitor que convive con algún hijo menor de 25 años"
    TYPE1 == 4, 9, # "2+ Adultos y 1 menor" -> "Hogar formado por pareja con hijos en donde algún hijo es menor de 25 años"
    TYPE1 == 5, 10, # "2+ Adultos y 2 menor" -> "Hogar formado por pareja con hijos en donde todos los hijos de 25 años o más"
    TYPE1 == 9, 7, # "2 adultos" -> "Hogar formado por pareja sin hijos"
    TYPE1 == 10, 8 # "3+ adultos" -> "Otro tipo de hogar"
  )]

  # Define TYPE3 to TYPE2 mapping
  dt[, TYPE2_from_TYPE3 := fcase(
    TYPE3 == 1, 1, # "Persona sola menor de 65 años" -> "Hogar con una mujer sola menor de 65 años"
    TYPE3 == 2, 3, # "Persona sola de 65 años o más" -> "Hogar con una mujer sola de 65 años o más"
    TYPE3 == 3, 5, # "Madre/padre solo con algún hijo menor de 25 años" -> "Hogar con un solo progenitor que convive con algún hijo menor de 25 años"
    TYPE3 %in% c(6, 8), 9, # "Pareja con hijos alguno menor de 25 años" or "Pareja con hijo de un solo miembro menor de 25" -> "Hogar formado por pareja con hijos en donde algún hijo es menor de 25 años"
    TYPE3 %in% c(7, 9), 10, # "Pareja con hijos todos mayores de 24" or "Pareja con hijo de un solo miembro todos mayores de 24" -> "Hogar formado por pareja con hijos en donde todos los hijos de 25 años o más"
    TYPE3 == 5, 7, # "Pareja sin hijos" -> "Hogar formado por pareja sin hijos"
    TYPE3 == 15, 8 # "Personas que no forman pareja y tienen parentesco distinto de padre e hijo" -> "Otro tipo de hogar"
  )]

  return(dt)
}

# Apply the mapping function to redefine TYPE1 and TYPE3 to align with TYPE2 as closely as possible
dt <- map_types(dt)

# View the results to analyze the mappings
print(dt)
