# Obtain population statistics for AEAT subsample

# clean enviroment to avoid ram bottlenecks and import dependencies

rm(list = ls())
library(survey)
library(magrittr)
library(dineq)
source("AEAT/src/etl_pipe.R")

# import needed data objects
selected <- "IDENHOG"
sel_year <- 2016
risks <- fread("AEAT/data/risk.csv")
dt <- get_wave(sel_year = sel_year, ref_unit = selected)

# hardcoded vars

net_var <- colnames(risks)[colnames(risks) %like% tolower(selected)]
risk_pov_tier <- risks[year == sel_year, get(net_var)]
dt[, RISK := 0][RENTAD < risk_pov_tier, RISK := 1]
dt[, CASERO2 := 0][RENTA_ALQ > 1200, CASERO2 := 1]

# Create the survey design object with the initial weights

survey_design <- svydesign(
    ids = ~1,
    data = dt,
    weights = dt$FACTORCAL
)

# Subsample for a reference municipio

subsample <- subset(survey_design, MUESTRA == 1)

# obtain quantiles for a given variable

quantiles <- svyquantile(~RENTA_ALQ, subsample, quantiles = c(0.1, 0.25, 0.5, 0.75, 0.90, 0.95, 0.99))
quant <- data.table(quantiles$RENTA_ALQ[, 1], seq_along(quantiles$RENTA_ALQ[, 1]) - 1)
colnames(quant) <- c("cuantil", "index")

# obtain inequality proportions

total_general <- svytotal(~RENTA_ALQ, subsample)["RENTA_ALQ"]
proportions <- list()
for (i in seq_along(quant$index)) {
    tier <- quant[index == i - 1]$cuantil
    quantil <- row.names(quantiles$RENTA_ALQ)[i]
    prop <- (svytotal(~RENTA_ALQ, subset(subsample, RENTA_ALQ > tier)) / total_general) %>% round(3)
    proportions[[i]] <- data.table(quantil = quantil, tier = tier, prop = prop[1])
}

# transform the list into a table

proportions <- rbindlist(proportions) %>% print()

# print some exploratoty results

prop_rentis <- svymean(~TENENCIA, survey_design) %>% print()
histrentaB <- svyhist(~RENTA_ALQ, design = subsample, breaks = 30)
risk_pop <- svymean(~RISK, subsample, FUN = svymean) %>% print()
renta_alq_gini <- gini.wtd(dt$RENTA_ALQ, dt$FACTORCAL) %>% print()
renta_alq_deco <- gini_decomp(dt$RENTAB, dt$TENENCIA)
renta_por_clase <- svyby(~RENTAD, ~TENENCIA, survey_design, svymean) %>% print()

svytotal(~NPROP_ALQ, subsample) %>%
    prop.table() %>%
    print()

svyquantile(~NPROP_ALQ, subsample, quantiles = seq(0.1, 1, 0.1)) %>% print()

svytable(~NPROP_ALQ, subsample) %>%
    prop.table() %>%
    View()
