source("LocalWealthHousing/AEAT/src/template.R")

# Create the survey design object with the initial weights
survey_design <- svydesign(
    ids = ~1,
    data = dt_sg,
    weights = dt_sg$FACTORCAL
) # Initial survey design with elevation factors

svymean(~RENTAD, survey_design) %>% print()
svymean(~RENTAB, survey_design) %>% print()


hist_rentaB <- svyhist(~RENTAB, survey_design)
cdf_rentaB <- svycdf(~RENTAB, survey_design)
