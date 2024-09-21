# Obtain population statistics for AEAT subsample
library(survey)
rm(list = ls()) # clean enviroment to avoid ram bottlenecks
source("AEAT/src/template.R")

# Create the survey design object with the initial weights
survey_design <- svydesign(
    ids = ~1,
    data = dt,
    weights = dt$FACTORCAL
)

# Subsample for a reference municipio
subsample <- subset(survey_design, MUESTRA == 1 & RENTA_ALQ > 0)

# calculate a few statistics
svymean(~RENTAB, subsample) %>% print()

hist_rentaB <- svyhist(
    ~RENTA_ALQ,
    design = subsample,
    breaks = 30,
    probability = TRUE
)

# obtain quantiles for a given variable
quantiles <- svyquantile(~RENTA_ALQ, subsample, quantiles = seq(0.5, 0.99, 0.05)) %>% print()
quant <- data.table(quantiles$RENTA_ALQ[, 1], seq_along(quantiles$RENTA_ALQ[, 1]) - 1)
colnames(quant) <- c("cuantil", "index")

# obtain inequality proportions
total_general <- svytotal(~RENTA_ALQ, subsample)["RENTA_ALQ"]
proportions <- list()
for (i in seq_along(quant$index) - 1) {
    tier <- quant[index == i]$cuantil
    quantil <- row.names(quantiles$RENTA_ALQ)[i]
    prop <- svytotal(~RENTA_ALQ, subset(subsample, RENTA_ALQ > tier)) / total_general
    proportions[[i + 1]] <- data.table(quantil = quantil, tier = tier, prop = prop)
}
proportions <- rbindlist(proportions)
print(proportions)
