# Fichero principal 2021
library(magrittr)
library(readr)
library(data.table)
rm(list = ls()) # clean enviroment to avoid ram bottlenecks

sel_year <- 2021
################################

# IDENTIFICADORES Y PESOS fichero 1_IDEN.txt
start_iden <- c(1, 12, 23, 25, 27, 35, 36) # Starting positions references
end_iden <- c(11, 22, 24, 26, 29, 35, 55) # Ending positions references
col_iden <- fwf_positions(start = start_iden, end = end_iden) # Use fwf_positions to define column positions
iden <- read_fwf(paste0("AEAT/data/original/1_IDEN", sel_year, ".txt"), col_positions = col_iden) %>% data.table()
colnames(iden) <- c("IDENPER", "IDENHOG", "CCAA", "PROV", "MUNI", "TRAMO", "FACTORCAL")


# IDENTIFICADORES Y PESOS fichero 10_IDEN.txt
start_iden2 <- c(1, 12, 13, 17) # Starting positions references
end_iden2 <- c(11, 12, 16, 19) # Ending positions references
col_iden2 <- fwf_positions(start = start_iden2, end = end_iden2) # Use fwf_positions to define column positions
iden2 <- read_fwf(paste0("AEAT/data/original/1_IDEN", sel_year, ".txt"), col_positions = col_iden2) %>% data.table()
colnames(iden2) <- c("IDENPER", "SEXO", "ANONAC", "PAISNAC")

# FUSIONAR EN FICHERO CON INDETIFICACIÓN COMPLETA
dt <- merge(iden, IDEN2, by = c("IDENPER"))
fwrite(iden, paste0("AEAT/data/ief2021/", sel_year, "_iden.gz"))
