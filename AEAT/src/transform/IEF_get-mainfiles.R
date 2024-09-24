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

# RENTA
if (sel_year == 2021) {
    start_positions <- c(1, 12, 707, 719, 191)
    end_positions <- c(11, 22, 718, 730, 202)
}
if (sel_year == 2016) {
    start_positions <- c(1, 12, 635, 647, 191)
    end_positions <- c(11, 22, 646, 658, 202)
}
col_positions <- fwf_positions(start = start_positions, end = end_positions) # Use fwf_positions to define column positions
test_total <- read_fwf(paste0("AEAT/data/original/2_Renta", sel_year, ".txt"), col_positions = col_positions) %>% data.table()
colnames(test_total) <- c("IDENPER", "IDENHOG", "RENTAB", "RENTAD", "RENTA_ALQ")

# PATRIMONIO
start_pat <- c(1, 12, 23)
end_pat <- c(11, 22, 42)
col_pat <- fwf_positions(start = start_pat, end = end_pat) # Use fwf_positions to define column positions
pat <- read_fwf(paste0("AEAT/data/original/5_Patrimonio", sel_year, ".txt"), col_positions = col_pat) %>% data.table()
colnames(pat) <- c("IDENPER", "IDENHOG", "PATINMO")


# RENTA TIPO DECLARANTE
if (sel_year == 2021) {
    start_dt_dec <- c(1, 12, 23)
    end_dt_dec <- c(11, 22, 25)
    col_dt_dec <- fwf_positions(start = start_dt_dec, end = end_dt_dec) # Use fwf_positions to define column positions
    dt_dec <- read_fwf(paste0("AEAT/data/original/4_IRPF", sel_year, ".txt"), col_positions = col_dt_dec) %>% data.table()
    colnames(dt_dec) <- c("IDENPER", "IDENHOG", "TIPODEC")
}
if (sel_year == 2016) {
    start_dt_dec <- c(1, 12, 23, 27, 29) # par150 (1491, 1502)
    end_dt_dec <- c(11, 22, 25, 27, 32)
    col_dt_dec <- fwf_positions(start = start_dt_dec, end = end_dt_dec) # Use fwf_positions to define column positions
    dt_dec <- read_fwf(paste0("AEAT/data/original/4_IRPF", sel_year, ".txt"), col_positions = col_dt_dec) %>% data.table()
    colnames(dt_dec) <- c("IDENPER", "IDENHOG", "TIPODEC", "SEXO", "ANONAC")
}

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

# Merge both datasets based on IDs
dt <- merge(iden, test_total, by = c("IDENPER", "IDENHOG"))
dt <- merge(dt, pat, by = c("IDENPER", "IDENHOG"))
dt <- merge(dt, dt_dec, by = c("IDENPER", "IDENHOG"))
dt <- merge(dt, dt150, by = c("IDENPER", "IDENHOG"))

fwrite(dt, paste0("AEAT/data/IEF-", sel_year, "-new.gz")) # exportar objeto preparado
