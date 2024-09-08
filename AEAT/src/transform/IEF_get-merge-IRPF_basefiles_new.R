# Fichero principal 2021
library(magrittr)
library(readr)
library(data.table)
rm(list = ls()) # clean enviroment to avoid ram bottlenecks

sel_year <- 2021
################################

# IDENTIFICADORES Y PESOS
start_iden <- c(1, 12, 23, 25, 27, 35, 36) # Starting positions references
end_iden <- c(11, 22, 24, 26, 29, 35, 55) # Ending positions references
col_iden <- fwf_positions(start = start_iden, end = end_iden) # Use fwf_positions to define column positions
iden <- read_fwf(paste0("AEAT/data/original/1_IDEN", sel_year, ".txt"), col_positions = col_iden) %>% data.table()
colnames(iden) <- c("IDENPER", "IDENHOG", "CCAA", "PROV", "MUNI", "TRAMO", "FACTORCAL")

# export data
fwrite(iden, paste0("AEAT/data/ief2021/", sel_year, "_iden.gz"))
