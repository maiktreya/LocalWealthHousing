source("AEAT/src/template.R")

dt2[, rentista := 0][RENTA_ALQ > 0, rentista := 1]
dt2[RENTA_ALQ < 0, RENTA_ALQ := 0]

# Create the survey design object with the initial weights
survey_design <- svydesign(
    ids = ~1,
    data = dt2,
    weights = dt2$FACTORCAL
) # Initial survey design with elevation factors

svymean(~RENTAD, subset(survey_design, segovia == 1)) %>% print()
svymean(~RENTAB, subset(survey_design, segovia == 1)) %>% print()
svymean(~rentista, subset(survey_design, segovia == 1)) %>% print()
svymean(~RENTA_ALQ, subset(survey_design, segovia == 1 & rentista == 1)) %>% print()
quantiles <- svyquantile(~RENTA_ALQ, subset(survey_design, segovia == 1 & RENTA_ALQ > 0), quantiles = seq(0, 1, 0.1)) %>% print()
upper <- quantiles$RENTA_ALQ[nrow(quantiles$RENTA_ALQ)]
lower <- quantiles$RENTA_ALQ[1]

hist_rentaB <- svyhist(
    ~RENTA_ALQ,
    design = subset(survey_design, segovia == 1 &  RENTA_ALQ < upper),
    breaks = 30,
    probability = TRUE
)
cdf_rentaB <- svycdf(~RENTAB, subset(survey_design, segovia == 1 & RENTAB < upper))

hist_rentaB <- svymean(~RENTA_ALQ, subset(survey_design, segovia == 1))
cdf_rentaB <- svycdf(~RENTA_ALQ, subset(survey_design, segovia == 1))
quant <- data.table(quantiles$RENTA_ALQ[, 1], seq_along(quantiles$RENTA_ALQ[, 1]) - 1)
colnames(quant) <- c("cuantil", "index")
