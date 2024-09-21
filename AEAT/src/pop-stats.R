# Obtain population statistics for IAT subsample
source("AEAT/src/template.R")

dt[, rentista := 0][RENTA_ALQ > 0, rentista := 1]
dt[RENTA_ALQ < 0, RENTA_ALQ := 0]

# Create the survey design object with the initial weights
survey_design <- svydesign(
    ids = ~1,
    data = dt,
    weights = dt$FACTORCAL
)

# Subsample for a reference municipio
subsample <- subset(survey_design, MUESTRA == 1)

svymean(~RENTAD, save.image(ubsample)) %>% print()
svymean(~RENTAB, save.image(ubsample)) %>% print()
svymean(~rentista, save.image(ubsample)) %>% print()
svymean(~RENTA_ALQ, subsample) %>% print()
quantiles <- svyquantile(~RENTA_ALQ, subsample, quantiles = seq(0, 1, 0.1)) %>% print()
upper <- quantiles$RENTA_ALQ[nrow(quantiles$RENTA_ALQ)]
lower <- quantiles$RENTA_ALQ[1]

hist_rentaB <- svyhist(
    ~RENTA_ALQ,
    design = subsample,
    breaks = 30,
    probability = TRUE
)
cdf_rentaB <- svycdf(~RENTAB, subset(subsample, RENTAB < upper))

hist_rentaB <- svymean(~RENTA_ALQ, save.image(ubsample))
cdf_rentaB <- svycdf(~RENTA_ALQ, save.image(ubsample))
quant <- data.table(quantiles$RENTA_ALQ[, 1], seq_along(quantiles$RENTA_ALQ[, 1]) - 1)
colnames(quant) <- c("cuantil", "index")
