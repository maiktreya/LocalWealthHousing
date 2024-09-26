# Rscript for Resampling Segovia from: https://chatgpt.com/share/66f53f75-76c4-8007-b2ab-529f437699cd

library("magrittr")
library("data.table")
library("survey")
rm(list = ls()) # Clean environment to avoid RAM bottlenecks

source("AEAT/src/transform/etl_pipe.R")
city <- "Segovia"
represet <- "!is.na(FACTORCAL)" # población
represet2 <- 'TIPODEC %in% c("T1", "T21") & !is.na(FACTORCAL)' # declarantes de renta
sel_year <- 2016
ref_unit <- "IDENHOG"
dt <- get_wave(sel_year = sel_year, ref_unit = ref_unit, represet = represet)
fr <- fread("AEAT/data/madrid-age.csv") # from INE population distribution

# Process the population data (assuming the first row contains overall totals)
sex <- fr[1, .(age, segoT, segoH, segoM)]
fr <- fr[-1, .(age, segoT, segoH, segoM)]

fr[, age_group := cut(as.numeric(age), breaks = seq(0, 100, by = 5), right = FALSE)]

# Summarize the population by age group
age_distribution <- fr[, .(Freq = sum(segoT) / sum(sex$segoT)), by = age_group]

gender_distribution <- data.table(
    gender = c("male", "female"),
    Freq = c(sex$segoH / sex$segoT, sex$segoM / sex$segoT)
)

# Ensure gender is categorical and matches the population margin
dt[, gender := ifelse(SEXO == 1, "male", "female")]

# Create age groups to match the age distribution
dt[, age_group := cut(age, breaks = seq(0, 100, by = 10), right = FALSE)]

# Remove rows with missing age groups (or impute missing values if needed)
dt <- dt[!is.na(age_group)]

# Check the structure of the age and gender variables
table(dt$age_group)
table(dt$gender)

























# Create the survey design object with the initial weights
survey_design <- svydesign(
    ids = ~1,
    data = dt,
    weights = dt$FACTORCAL
) # Initial survey design with elevation factors

# Restrict the survey to the city of interest
survey_design_segovia <- subset(survey_design, segovia == 1)

# Get the unique age groups from the sample data
unique_age_groups <- unique(dt[segovia == 1, age_group])

# Subset the population margin to include only age groups present in the sample
age_distribution <- age_distribution[age_group %in% unique_age_groups]

# Proceed with the raking process
raked_design <- rake(
    design = survey_design_segovia,
    sample.margins = list(~age_group, ~gender),
    population.margins = list(age_distribution, gender_distribution)
)

# Rescale the raked weights to match Segovia's total population
total_population_segovia <- sum(sex$segoT)
raked_weights <- weights(raked_design)
rescaled_weights <- raked_weights * (total_population_segovia / sum(raked_weights))

# Update the survey design with the rescaled weights
raked_design <- update(raked_design, weights = rescaled_weights)

# Check the rescaled weights
print(rescaled_weights)

# Example analysis: Weighted mean of income after raking and rescaling
weighted_mean_income <- svymean(~RENTAB, raked_design)
preweighted_mean_income <- svymean(~RENTAB, survey_design)

# Output the results
print(weighted_mean_income)
print(preweighted_mean_income)
