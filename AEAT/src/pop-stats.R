# Obtain population statistics for AEAT subsample
source("AEAT/src/template.R")

dt[, RENTISTA := 0][RENTA_ALQ > 0, RENTISTA := 1]
dt[RENTA_ALQ < 0, RENTA_ALQ := 0]

# Create the survey design object with the initial weights
survey_design <- svydesign(
    ids = ~1,
    data = dt,
    weights = dt$FACTORCAL
)

# Subsample for a reference municipio
subsample <- subset(survey_design, MUESTRA == 1)

svymean(~RENTAD, subsample) %>% print()
svymean(~RENTAB, subsample) %>% print()
svymean(~RENTISTA, subsample) %>% print()
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

hist_rentaB <- svymean(~RENTA_ALQ, subsample)
cdf_rentaB <- svycdf(~RENTA_ALQ, subsample)
quant <- data.table(quantiles$RENTA_ALQ[, 1], seq_along(quantiles$RENTA_ALQ[, 1]) - 1)
colnames(quant) <- c("cuantil", "index")
