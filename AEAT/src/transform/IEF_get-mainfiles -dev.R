# Piping AEAT anual realease files into a single efficient data.table matrix stored as gz file

library(magrittr)
library(readr)
library(data.table)
rm(list = ls()) # clean enviroment to avoid ram bottlenecks

# main data and hardcoded vars

sel_year <- 2021
dt <- fread(paste0("AEAT/data/IEF-", sel_year, "-new-old.gz")) # from IEAT IRPF sample

# IDENTIFICADORES Y PESOS fichero 1_IDEN.txt
start_iden <- c(1, 12, 23, 25, 27, 35, 36, 132) # Starting positions references
end_iden <- c(11, 22, 24, 26, 29, 35, 55, 141) # Ending positions references
col_iden <- fwf_positions(start = start_iden, end = end_iden) # Use fwf_positions to define column positions
iden <- read_fwf(paste0("AEAT/data/original/1_IDEN", sel_year, ".txt"), col_positions = col_iden) %>% data.table()
colnames(iden) <- c("IDENPER", "IDENHOG", "CCAA", "PROV", "MUNI", "TRAMO", "FACTORCAL", "SECCION")


# Merge both datasets based on IDs
dt <- merge(dt, iden, by = c("IDENPER", "IDENHOG"))

# export the results

fwrite(dt, paste0("AEAT/data/IEF-", sel_year, "-new.gz")) # exportar objeto preparado
