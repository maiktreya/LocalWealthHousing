# Clean environment and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
library(openxlsx)

# read base data
migr1 <- fread("AEAT/out/madrid/madrid-2016-IDENHOGmigr.csv")[, wave := 2016]
migr2 <- fread("AEAT/out/madrid/madrid-2021-IDENHOGmigr.csv")[, wave := 2021]
real1 <- fread("AEAT/out/madrid/madrid-2016-IDENHOGreal_estate.csv")[, wave := 2016]
real2 <- fread("AEAT/out/madrid/madrid-2021-IDENHOGreal_estate.csv")[, wave := 2021]
rent1 <- fread("AEAT/out/madrid/madrid-2016-IDENHOGtabla-renta.csv")[, wave := 2016]
rent2 <- fread("AEAT/out/madrid/madrid-2021-IDENHOGtabla-renta.csv")[, wave := 2021]
quan1 <- fread("AEAT/out/madrid/madrid-2016-IDENHOGtabla-quantiles.csv")[, wave := 2016]
quan2 <- fread("AEAT/out/madrid/madrid-2021-IDENHOGtabla-quantiles.csv")[, wave := 2021]
tena1 <- fread("AEAT/out/madrid/madrid-2016-IDENHOGreg_tenencia.csv")[, wave := 2016]
tena2 <- fread("AEAT/out/madrid/madrid-2021-IDENHOGreg_tenencia.csv")[, wave := 2021]

# Merge annual data

migr <- rbind(migr1, migr2) %>% fwrite(file = "AEAT/out/madrid/final/madrid-migr.csv")
real <- rbind(real1, real2) %>% fwrite(file = "AEAT/out/madrid/final/madrid-real_estate.csv")
rent <- rbind(rent1, rent2) %>% fwrite(file = "AEAT/out/madrid/final/madrid-tabla-renta.csv")
quan <- rbind(quan1, quan2) %>% fwrite(file = "AEAT/out/madrid/final/madrid-tabla-quantiles.csv")
tena <- rbind(tena1, tena2) %>% fwrite(file = "AEAT/out/madrid/final/madrid-reg_tenencia.csv")

# Read merged data
migr <- fread("AEAT/out/madrid/final/madrid-migr.csv")
real <- fread("AEAT/out/madrid/final/madrid-real_estate.csv")
rent <- fread("AEAT/out/madrid/final/madrid-tabla-renta.csv")
quan <- fread("AEAT/out/madrid/final/madrid-tabla-quantiles.csv")
tena <- fread("AEAT/out/madrid/final/madrid-reg_tenencia.csv")

# Define the output folder and file name
output_folder <- "AEAT/out/madrid/final/"
output_file <- paste0(output_folder, "madrid_data.xlsx")

# Create a new workbook
wb <- createWorkbook()

# List of data.tables to export
data_list <- list(
  migr = migr,
  real = real,
  rent = rent,
  quan = quan,
  tena = tena
)

# Loop through the list and add each data.table to a new sheet
for (name in names(data_list)) {
  addWorksheet(wb, name)
  writeData(wb, sheet = name, data_list[[name]], rowNames = FALSE)
}

# Save the workbook
saveWorkbook(wb, file = output_file)
