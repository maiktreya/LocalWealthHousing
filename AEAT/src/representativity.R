source("AEAT/src/template.R")

dt2[, rentista := 0][RENTA_ALQ > 0, rentista := 1]
dt2[RENTA_ALQ < 0, RENTA_ALQ := 0]

# Create the survey design object with the initial weights
survey_design <- svydesign(
    ids = ~1,
    data = dt2,
    weights = dt2$FACTORCAL
)

# performe representativness test on key variables with known distributional values
test_rep1 <- svyttest(I(RENTAD - 34272) ~ 0, subset(survey_design, segovia == 1)) %>% print()
test_rep2 <- svyttest(I(RENTAB - 41235) ~ 0, subset(survey_design, segovia == 1)) %>% print()
confint