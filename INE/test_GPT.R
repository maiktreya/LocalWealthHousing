library(data.table)

# Example TYPE1, TYPE2, TYPE3 data.tables
TYPE1 <- data.table(code = 1:10, desc = c(
  "Hogar unipersonal -65", "Hogar unipersonal +65", "Hogar con un solo +18", 
  "2+ Adultos y 1 menor", "2+ Adultos y 2 menor", "2+ Adultos y 3+ menor", 
  "2 adultos (sin menores y alguno +65)", "3+ adultos (sin menores y alguno +65)", 
  "2 adultos", "3+ adultos"
))

TYPE2 <- data.table(code = 1:8, desc = c(
  "Hogar unipersonal", "Hogar de una familia sin otras personas adicionales y sólo un núcleo", 
  "Hogar multipersonal pero que no forma familia", "Hogar de una familia sin otras personas adicionales y ningún núcleo", 
  "Hogar de una familia sin otras personas adicionales y un núcleo y otras personas", "Hogar de una familia, con otras personas no emparentadas", 
  "Hogar de una familia sin otras personas adicionales y dos núcleos o más", "Hogar de dos o más familias"
))

TYPE3 <- data.table(code = 1:16, desc = c(
  "Persona sola menor de 65 años", "Persona sola de 65 años o más", "Madre/padre solo con algún hijo menor de 25 años", 
  "Madre/padre solo con algún hijo todos mayores de 24 años", "Pareja sin hijos que convivan en el hogar", 
  "Pareja con hijos de ambos miembros que conviven en el hogar alguno menor de 25 años", 
  "Pareja con hijos de ambos miembros que conviven en el hogar todos mayores de 24 años", 
  "Pareja con algún hijo de un solo miembro y además alguno de los hijos menor de 25 años (4.2.1)", 
  "Pareja con algún hijo de un solo miembro que conviven en el hogar todos mayores de 24 años (4.2.2)", 
  "Pareja con algún hijo menor de 25 años y otras personas", "Madre/padre con algún hijo menor de 25 años y otras personas", 
  "Pareja o Madre/padre con algún hijo todos mayores de 24 años y otras personas", "Pareja sin hijos y otros familiares", 
  "Pareja sin hijos y otras personas alguna de ellas no tiene relación de parentesco con la pareja", 
  "Personas que no forman pareja y si tienen parentesco es distinto de padre e hijo", "Otros (más de un núcleo)"
))

# Define mappings for TYPE2 and TYPE3 to TYPE1
# This can be adjusted based on the mappings described in the previous response
mapping_TYPE2_TO_TYPE1 <- data.table(
  TYPE2_code = 1:8,
  TYPE1_code = c(1, 9, 10, 9, 7, 8, 6, 10)  # Adjusted based on the logical mapping described
)

mapping_TYPE3_TO_TYPE1 <- data.table(
  TYPE3_code = 1:16,
  TYPE1_code = c(1, 2, 3, 3, 9, 4, 9, 4, 9, 6, 3, 9, 10, 10, 10, 10)  # Adjusted based on the logical mapping described
)

# Merge mappings to redefine TYPE2 and TYPE3 to align with TYPE1
TYPE2_aligned <- merge(TYPE2, mapping_TYPE2_TO_TYPE1, by.x = "code", by.y = "TYPE2_code", all.x = TRUE)
TYPE2_aligned <- merge(TYPE2_aligned, TYPE1, by.x = "TYPE1_code", by.y = "code", suffixes = c("_TYPE2", "_TYPE1"))

TYPE3_aligned <- merge(TYPE3, mapping_TYPE3_TO_TYPE1, by.x = "code", by.y = "TYPE3_code", all.x = TRUE)
TYPE3_aligned <- merge(TYPE3_aligned, TYPE1, by.x = "TYPE1_code", by.y = "code", suffixes = c("_TYPE3", "_TYPE1"))

# View the results
type2_result <- TYPE2_aligned[, .(code_TYPE2 = code, desc_TYPE2 = desc_TYPE2, TYPE1_code, desc_TYPE1)]
type3_result <- TYPE3_aligned[, .(code_TYPE3 = code, desc_TYPE3 = desc_TYPE3, TYPE1_code, desc_TYPE1)]

# Print the aligned classifications
print( c(1:11)[!c(1:11) %in% type3_result$TYPE1_code])
print( c(1:11)[!c(1:11) %in% type2_result$TYPE1_code])
