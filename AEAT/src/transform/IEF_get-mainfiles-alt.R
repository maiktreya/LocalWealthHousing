# Piping AEAT anual realease files into a single efficient data.table matrix stored as gz file

library(magrittr)
library(readr)
library(data.table)
rm(list = ls()) # clean enviroment to avoid ram bottlenecks

sel_year <- 2016
################################

# IDENTIFICADORES Y PESOS fichero 1_IDEN.txt
start_iden <- c(1, 12, 23, 25, 27, 35, 36, 132) # Starting positions references
end_iden <- c(11, 22, 24, 26, 29, 35, 55, 141) # Ending positions references
col_iden <- fwf_positions(start = start_iden, end = end_iden) # Use fwf_positions to define column positions
iden <- read_fwf(paste0("AEAT/data/original/1_IDEN", sel_year, ".txt"), col_positions = col_iden) %>% data.table()
colnames(iden) <- c("IDENPER", "IDENHOG", "CCAA", "PROV", "MUNI", "TRAMO", "FACTORCAL", "SECCION")


# RENTA TIPO DECLARANTE
start_dt_dec <- c(1, 12, 23, 27, 29, 1491, 1011)
end_dt_dec <- c(11, 22, 25, 27, 32, 1502, 1022)
col_dt_dec <- fwf_positions(start = start_dt_dec, end = end_dt_dec) # Use fwf_positions to define column positions
dt_dec <- read_fwf(paste0("AEAT/data/original/4_IRPF", sel_year, ".txt"), col_positions = col_dt_dec) %>% data.table()
colnames(dt_dec) <- c("IDENPER", "IDENHOG", "TIPODEC", "SEXO", "ANONAC", "PAR150", "INCALQ")

# RENDIMIENTOS INMOBILIARIOS 2016 (par60-ingresos, par71-reduccioneq-par150)

start_dt150 <- c(1, 12, 23, 71, 203)
end_dt150 <- c(11, 22, 33, 82, 214)
col_dt150 <- fwf_positions(start = start_dt150, end = end_dt150) # Use fwf_positions to define column positions
dt150 <- read_fwf(paste0("AEAT/data/original/8_IRPF", sel_year, "_RRII.txt"), col_positions = col_dt150) %>% data.table()
colnames(dt150) <- c("IDENPER", "IDENHOG", "REFCAT", "INCALQ", "PAR150i")
