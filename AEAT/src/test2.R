source("AEAT/src/template.R")

dt_sg[, rentista := 0][RENTA_ALQ > 0, rentista := 1]
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

hist_rentaB <- svyhist(~RENTAB, survey_design)
cdf_rentaB <- svycdf(~RENTAB, survey_design)

hist_rentaB <- svymean(~RENTA_ALQ, survey_design)
cdf_rentaB <- svycdf(~RENTA_ALQ, survey_design)
