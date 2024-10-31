# Clean environment and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
library(openxlsx)

# Read data
migr <- fread("AEAT/out/segovia/final/segovia-migr.csv")
real <- fread("AEAT/out/segovia/final/segovia-real_estate.csv")
rent <- fread("AEAT/out/segovia/final/segovia-tabla-renta.csv")
quan <- fread("AEAT/out/segovia/final/segovia-tabla-quantiles.csv")
tena <- fread("AEAT/out/segovia/final/segovia-reg_tenencia.csv")

# Define the output folder and file name
output_folder <- "AEAT/out/segovia/final/"
output_file <- paste0(output_folder, "segovia_data.xlsx")

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
saveWorkbook(wb, file = output_file, overwrite = TRUE)
