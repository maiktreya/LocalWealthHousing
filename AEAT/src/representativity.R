# Obtain t-statisctics for representative mean forAEAT subsample

source("AEAT/src/template.R")

dt[, rentista := 0][RENTA_ALQ > 0, rentista := 1]
dt[RENTA_ALQ < 0, RENTA_ALQ := 0]

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
confint(test_rep1, level = 0.95) %>% print()
confint(test_rep2, level = 0.95) %>% print()
