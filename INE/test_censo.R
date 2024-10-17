rm(list = ls())
library(data.table)
library(magrittr)
library(survey)

dt <- readxl::read_xlsx("INE/censo_2021/Censo_2021.xlsx", sheet = "SgDT") %>% data.table()
