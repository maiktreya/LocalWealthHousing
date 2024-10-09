# clean enviroment and import dependencies
rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
library(readxl)

# define city subsample and variables to analyze
export_object <- FALSE
city <- "madrid"
represet <- "!is.na(FACTORCAL)"
sel_year <- 2016
ref_unit <- "IDENHOG"
rake_mode <- TRUE
calib_mode <- FALSE

tipohog_pop <- read_excel("AEAT/data/base_hogar/madrid-hog2020.xlsx", sheet = "Sheet5")  %>% data.table()

tipohog_pop <- tipohog_pop[Tipohog != "T", ][, index := .I]

setorder(tipohog_pop, Tipohog)

tipohog_pop %>% print()

fwrite(tipohog_pop, "AEAT/data/tipohog-madrid-2021.csv")

# dt <- fread("AEAT/data/IEF-2016-new.gz")