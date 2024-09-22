# Obtain t-statisctics for representative mean forAEAT subsample
library(survey)
rm(list = ls()) # clean enviroment to avoid ram bottlenecks
source("AEAT/src/template.R")

# Create the survey design object with the initial weights
survey_design <- svydesign(
    ids = ~1,
    data = dt,
    weights = dt$FACTORCAL
)
subsample <- subset(survey_design, MUESTRA == 1)

# performe representativness test on key variables with known distributional values
test_rep1 <- svyttest(I(RENTAD - 34272) ~ 0, subsample) %>% print()
test_rep2 <- svyttest(I(RENTAB - 41235) ~ 0, subsample) %>% print()
test_conf1 <- confint(test_rep1, level = 0.95) %>% print()
test_conf2 <- confint(test_rep2, level = 0.95) %>% print()
