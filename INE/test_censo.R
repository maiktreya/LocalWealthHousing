rm(list = ls())
library(data.table)
library(magrittr)
library(survey)

dt <- readxl::read_xlsx("INE/censo_2021/Censo_2021.xlsx", sheet = "SgDT") %>% data.table()

uni_mas65 <- c(
    "Hogar con una mujer sola mayor de 65 años",
    "Hogar con un hombre solo mayor de 65 años"
)
uni_menos65 <- c(
    "Hogar con una mujer sola menor de 65 años",
    "Hogar con un hombre solo menor de 65 años"
)
pareja_menor <- c("Hogar formado por pareja con hijos en donde algún hijo es menor de 25 años")

unipersonal_mas65 <- dt[SIZE == 1 & STRUCTURE %in% uni_mas65, .SD]
unipersonal_menos65 <- dt[SIZE == 1 & STRUCTURE %in% uni_menos65, .SD]
unipersonal_con_menor <- dt[SIZE == 2 & STRUCTURE == "Hogar con un solo progenitor que convive con algún hijo menor de 25 años", .SD]

pareja_con_1menor <- dt[SIZE == 3 & STRUCTURE == pareja_menor, .SD]
pareja_con_2menor <- dt[SIZE == 4 & STRUCTURE == pareja_menor, .SD]
pareja_con_3menor <- dt[SIZE == 5 & STRUCTURE == pareja_menor, .SD]
