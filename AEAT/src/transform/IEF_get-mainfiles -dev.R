# Piping AEAT anual realease files into a single efficient data.table matrix stored as gz file

# clean enviroment to avoid ram bottlenecks and import dependencies

rm(list = ls())
library(magrittr)
library(readr)
library(data.table)

# main data and hardcoded vars

sel_year <- 2021

# IDENTIFICADORES Y PESOS fichero 1_IDEN.txt

start_iden <- c(1, 12, 23, 25, 27, 35, 36, 132) # Starting positions references
end_iden <- c(11, 22, 24, 26, 29, 35, 55, 141) # Ending positions references
col_iden <- fwf_positions(start = start_iden, end = end_iden) # Use fwf_positions to define column positions
iden <- read_fwf(paste0("AEAT/data/original/1_IDEN", sel_year, ".txt"), col_positions = col_iden) %>% data.table()
colnames(iden) <- c("IDENPER", "IDENHOG", "CCAA", "PROV", "MUNI", "TRAMO", "FACTORCAL", "SECCION")

# PAR150 REDUCCIÓN ALQUILER VIVIENDA solo comprobado para 2021!

if (sel_year == 2021) {
    start_dt150 <- c(1, 12, 23, 154, 962)
    end_dt150 <- c(11, 22, 33, 173, 981)
    col_dt150 <- fwf_positions(start = start_dt150, end = end_dt150) # Use fwf_positions to define column positions
    dt150 <- read_fwf(paste0("AEAT/data/original/8_IRPF", sel_year, "_RRII.txt"), col_positions = col_dt150) %>% data.table()
    colnames(dt150) <- c("IDENPER", "IDENHOG", "REFCAT", "INCALQ", "PAR150i")
}
if (sel_year == 2016) {
    start_p150 <- c(1, 12, 23, 71, 203)
    end_p150 <- c(11, 22, 33, 82, 214)
    col_p150 <- fwf_positions(start = start_p150, end = end_p150) # Use fwf_positions to define column positions
    dt150 <- read_fwf(paste0("AEAT/data/original/8_IRPF", sel_year, "_RRII.txt"), col_positions = col_p150) %>% data.table()
    colnames(dt150) <- c("IDENPER", "IDENHOG", "REFCAT", "INCALQ", "PAR150i")
}


# export the results


fwrite(iden, paste0("AEAT/data/IEF-", sel_year, "-part.gz")) # exportar objeto preparado
fwrite(dt150, paste0("AEAT/data/IEF-", sel_year, "-150.gz")) # exportar objeto preparado
