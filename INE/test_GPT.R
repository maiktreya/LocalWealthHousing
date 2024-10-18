library(data.table)
library(magrittr)
# Define TYPE1, TYPE2, TYPE3 data.table objects
TYPE1 <- data.table(
  code = 1:11,
  desc = c(
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
)

TYPE2 <- data.table(
  code = 1:8,
  desc = c(
    "Hogar unipersonal",
    "Hogar de una familia sin otras personas adicionales y sólo un núcleo",
    "Hogar multipersonal pero que no forma familia",
    "Hogar de una familia sin otras personas adicionales y ningún núcleo",
    "Hogar de una familia sin otras personas adicionales y un núcleo y otras personas",
    "Hogar de una familia, con otras personas no emparentadas",
    "Hogar de una familia sin otras personas adicionales y dos núcleos o más",
    "Hogar de dos o más familias"
  )
)

TYPE3 <- data.table(
  code = 1:16,
  desc = c(
    "Persona sola menor de 65 años",
    "Persona sola de 65 años o más",
    "Madre/padre solo con algún hijo menor de 25 años",
    "Madre/padre solo con algún hijo todos mayores de 24 años",
    "Pareja sin hijos que convivan en el hogar",
    "Pareja con hijos de ambos miembros que conviven en el hogar alguno menor de 25 años",
    "Pareja con hijos de ambos miembros que conviven en el hogar todos mayores de 24 años",
    "Pareja con algún hijo de un solo miembro y además alguno de los hijos menor de 25 años (4.2.1)",
    "Pareja con algún hijo de un solo miembro que conviven en el hogar todos mayores de 25 años (4.2.2)",
    "Pareja con algún hijo menor de 25 años y otras personas",
    "Madre/padre con algún hijo menor de 25 años y otras personas",
    "Pareja o Madre/padre con algún hijo todos mayores de 24 años y otras personas",
    "Pareja sin hijos y otros familiares",
    "Pareja sin hijos y otras personas alguna de ellas no tiene relación de parentesco con la pareja",
    "Personas que no forman pareja y si tienen parentesco es distinto de padre e hijo",
    "Otros (más de un núcleo)"
  )
)

# Create mapping for TYPE2 to align with TYPE1
type2_mapping <- data.table(
  code = c(1, 2, 3, 4, 5, 6, 7, 8),
  new_code = c(
    1,                      # Hogar unipersonal aligns with TYPE1 codes 1, 2, 3, 4
    2,                      # Family without additional people (single family nucleus)
    8,                      # Non-family households
    8,                      # Non-family households without a nucleus
    11,                     # Family with additional people
    11,                     # Family with non-relatives
    11,                     # Multi-family households (2 or more nuclei)
    11                      # Two or more families
  )
)

# Merge the mapping with TYPE2 and update TYPE2 codes accordingly
TYPE2 <- merge(TYPE2, type2_mapping, by = "code", all.x = TRUE)
TYPE2[, code := new_code][, new_code := NULL]

# Create mapping for TYPE3 to align with TYPE1
type3_mapping <- data.table(
  code = 1:16,
  new_code = c(
    1,                      # Single individual <65
    3,                      # Single individual 65+
    5,                      # Single parent with children <25
    6,                      # Single parent with children >=25
    7,                      # Couple without children
    9,                      # Couple with children <25
    10,                     # Couple with children >=25
    9,                      # Couple with children (one parent) <25
    10,                     # Couple with children (one parent) >=25
    11,                     # Couple with children and others
    11,                     # Single parent with children and others
    11,                     # Parent or couple with older children and others
    11,                     # Couple without children with other family members
    11,                     # Couple without children with unrelated members
    8,                      # Non-family multi-person household
    8                       # Other types (more than one nucleus)
  )
)

# Merge the mapping with TYPE3 and update TYPE3 codes accordingly
TYPE3 <- merge(TYPE3, type3_mapping, by = "code", all.x = TRUE)
TYPE3[, code := new_code][, new_code := NULL]

faltan_en3 <- c(1:11)[!c(1:11) %in% TYPE3$code] %>% print()
faltan_en2 <- c(1:11)[!c(1:11) %in% TYPE2$code] %>% print()