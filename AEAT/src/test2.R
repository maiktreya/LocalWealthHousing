source("AEAT/src/template.R")

dt_sg[, rentista := 0][RENTA_ALQ > 0, rentista := 1]
dt_sg[RENTA_ALQ < 0, RENTA_ALQ := 0]

# Create the survey design object with the initial weights
survey_design <- svydesign(
    ids = ~1,
    data = dt_sg,
    weights = dt_sg$FACTORCAL
) # Initial survey design with elevation factors

svymean(~RENTAD, survey_design) %>% print()
svymean(~RENTAB, survey_design) %>% print()
svymean(~rentista, survey_design) %>% print()
svymean(~RENTA_ALQ, subset(survey_design, rentista == 1)) %>% print()
quantiles <- svyquantile(~RENTA_ALQ, subset(survey_design, RENTA_ALQ>0), quantiles = seq(0, 1, 0.1)) %>% print()
upper <- quantiles$RENTA_ALQ[nrow(quantiles$RENTA_ALQ)]
lower <- quantiles$RENTA_ALQ[1]

hist_rentaB <- svyhist(
    ~RENTA_ALQ,
    design = subset(survey_design, RENTA_ALQ < upper),
    breaks = 30,
    probability = TRUE
)
cdf_rentaB <- svycdf(~RENTAB, subset(survey_design, RENTAB < upper))

hist_rentaB <- svymean(~RENTA_ALQ, survey_design)
cdf_rentaB <- svycdf(~RENTA_ALQ, survey_design)



quant <- data.table(quantiles$RENTA_ALQ[,1],seq(length(quantiles$RENTA_ALQ[,1]))-1) # nolint: commas_linter.
colnames(quant) <- c("cuantil", "index")
dt_sg