# Fichero principal 2021
library(magrittr)
library(readr)
library(data.table)
rm(list = ls()) # clean enviroment to avoid ram bottlenecks

sel_year <- 2016
################################

# IDENTIFICADORES Y PESOS fichero 1_IDEN.txt
start_iden <- c(1, 12, 23, 25, 27, 35, 36) # Starting positions references
end_iden <- c(11, 22, 24, 26, 29, 35, 55) # Ending positions references
col_iden <- fwf_positions(start = start_iden, end = end_iden) # Use fwf_positions to define column positions
iden <- read_fwf(paste0("AEAT/data/original/1_IDEN", sel_year, ".txt"), col_positions = col_iden) %>% data.table()
colnames(iden) <- c("IDENPER", "IDENHOG", "CCAA", "PROV", "MUNI", "TRAMO", "FACTORCAL")


# RENTA
if (sel_year == 2021) {
    start_positions <- c(1, 12, 707, 719, 191)
    end_positions <- c(11, 22, 718, 730, 202)
    col_positions <- fwf_positions(start = start_positions, end = end_positions) # Use fwf_positions to define column positions
test_total <- read_fwf(paste0("AEAT/data/original/2_Renta", sel_year, ".txt"), col_positions = col_positions) %>% data.table()
colnames(test_total) <- c("IDENPER", "IDENHOG", "RENTAB", "RENTAD", "RENTA_ALQ")
}
if (sel_year == 2016) {
    start_positions <- c(1, 12, 27,29, 635, 647, 191)
    end_positions <- c(11, 22, 27, 32, 646, 658, 202)
    col_positions <- fwf_positions(start = start_positions, end = end_positions) # Use fwf_positions to define column positions
test_total <- read_fwf(paste0("AEAT/data/original/2_Renta", sel_year, ".txt"), col_positions = col_positions) %>% data.table()
colnames(test_total) <- c("IDENPER", "IDENHOG", "SEXO","ANONAC","RENTAB", "RENTAD", "RENTA_ALQ")
}

# PATRIMONIO
start_pat <- c(1, 12, 23)
end_pat <- c(11, 22, 42)
col_pat <- fwf_positions(start = start_pat, end = end_pat) # Use fwf_positions to define column positions
pat <- read_fwf(paste0("AEAT/data/original/5_Patrimonio", sel_year, ".txt"), col_positions = col_pat) %>% data.table()
colnames(pat) <- c("IDENPER", "IDENHOG", "PATINMO")

# RENTA TIPO DECLARANTE solo comprobado para 2021! huge size, different external path
start_dt_dec <- c(1, 12, 23)
end_dt_dec <- c(11, 22, 25)
col_dt_dec <- fwf_positions(start = start_dt_dec, end = end_dt_dec) # Use fwf_positions to define column positions
dt_dec <- read_fwf(paste0("AEAT/data/original/4_IRPF", sel_year, ".txt"), col_positions = col_dt_dec) %>% data.table()
colnames(dt_dec) <- c("IDENPER", "IDENHOG", "TIPODEC")
nrow(dt_dec) %>% print()

# PAR150 REDUCCIÓN ALQUILER VIVIENDA solo comprobado para 2021!
if (sel_year == 2021) {
    start_dt150 <- c(1, 12, 962)
    end_dt150 <- c(11, 22, 981)
}
if (sel_year == 2016) {
    start_dt150 <- c(1, 12, 627)
    end_dt150 <- c(11, 22, 638)
}
col_dt150 <- fwf_positions(start = start_dt150, end = end_dt150) # Use fwf_positions to define column positions
dt150 <- read_fwf(paste0("AEAT/data/original/8_IRPF", sel_year, "_RRII.txt"), col_positions = col_dt150) %>% data.table()
colnames(dt150) <- c("IDENPER", "IDENHOG", "PAR150")

# Merge both datasets based on IDs
dt <- merge(iden, test_total, by = c("IDENPER", "IDENHOG"))
dt <- merge(dt, pat, by = c("IDENPER", "IDENHOG"))
dt <- merge(dt, dt_dec, by = c("IDENPER", "IDENHOG"))
dt <- merge(dt, dt150, by = c("IDENPER", "IDENHOG"))

fwrite(dt, paste0("AEAT/data/original/", sel_year, "dt.gz"))
