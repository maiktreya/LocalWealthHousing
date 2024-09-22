# Obtain population statistics for AEAT subsample
library(survey)
library(dineq)
rm(list = ls()) # clean enviroment to avoid ram bottlenecks
source("AEAT/src/template.R")

# hardcoded varss
# svyquantile(~RENTAD, survey_design, quantiles = c(.5))[1]$RENTAD[,"quantile"]*.6 # nolint
if (sel_year == 2016) {
    ifelse(ref_unit == "IDENHOG", risk_pov_tier <- 14610, risk_pov_tier <- 4833)
}
if (sel_year == 2021) {
    ifelse(ref_unit == "IDENHOG", risk_pov_tier <- 16097, risk_pov_tier <- 6032)
}
dt[, RISK := 0][RENTAD < risk_pov_tier, RISK := 1]

# Create the survey design object with the initial weights
survey_design <- svydesign(
    ids = ~1,
    data = dt,
    weights = dt$FACTORCAL
)

# Subsample for a reference municipio
subsample <- subset(survey_design, MUESTRA == 1 & RENTA_ALQ > 0)

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

# export the output
fwrite(proportions, file = paste0("AEAT/out/concentracion-caseros-", ref_unit, "-", sel_year, ".csv"))

# print some exploratoty results
prop_rentis <- svymean(~RENTISTA, survey_design) %>% print()
renta_media <- svymean(~RENTAB, subsample) %>% print()
histrentaB <- svyhist(~RENTA_ALQ, design = subsample, breaks = 30)
risk_pop <- svymean(~RISK, subsample, FUN = svymean) %>% print()
renta_alq_gini <- gini.wtd(dt$RENTA_ALQ, dt$FACTORCAL) %>% print()
renta_alq_deco <- gini_decomp(dt$RENTAB, dt$RENTISTA)
