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

tipohog_pop <- fread(paste0("AEAT/data/tipohog-", city, "-", sel_year, ".csv"))

dt <- fread("AEAT/data/IEF-2016-new.gz")

subsample_cp <- subsample
subsample <- trimWeights(subsample_cp, lower = 0, upper = 1000, strict = TRUE)

# 25/77845
# [1] 0.000321151
