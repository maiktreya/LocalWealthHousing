# Rscript for Resampling Segovia
library("magrittr")
library("data.table")
library("survey")
rm(list = ls()) # Clean environment to avoid RAM bottlenecks

ref_survey <- "IEF" # Either IEF or EFF
ref_unit <- "IDENPER" # Use either IDENPER for personal or IDENHOG for household levels
selected_columns <- c("RENTAD", "RENTAB", "RENTA_ALQ", "PATINMO")

# Import chosen dataframe (change string according to the data file path)
dt <- fread("LocalWealthHousing/AEAT/data/IEF-2021-new.gz")
fr <- fread("LocalWealthHousing/AEAT/data/ief2021/pob-segovia.csv")

# Process the population data (assuming the first row contains overall totals)
sex <- fr[1, .(age, segoT, segoH, segoM)]
fr <- fr[-1, .(age, segoT, segoH, segoM)]

# Create the age and gender distributions based on the population data
age_distribution <- data.table(
  age_group = c("[0,10)", "[10,20)", "[20,30)", "[30,40)", "[40,50)", "[50,60)", "[60,70)", "[70,80)", "[80,90)", "[90,100)"),
  Freq = fr$segoT / sum(sex$segoT)  # Adjusted to match population proportions
)

gender_distribution <- data.table(
  gender = c("male", "female"),
  Freq = c(sex$segoH / sex$segoT, sex$segoM / sex$segoT)
)

# Replace NA values with 0 in selected columns
dt[, (selected_columns) := lapply(.SD, function(x) ifelse(is.na(x), 0, x)), .SDcols = selected_columns]

# Main data transformation: Filter rows and summarize
dt[TRAMO == "N", TRAMO := 8][, TRAMO := as.numeric(TRAMO)]

dt <- dt[TIPODEC %in% c("T1", "T21") & !is.na(FACTORCAL),
    .(
        SEXO = mean(SEXO),  # 1 = Male, 2 = Female
        age = 2022 - mean(ANONAC),  # Calculate age
        RENTAB = sum(RENTAB),
        RENTAD = sum(RENTAD),
        TRAMO = mean(TRAMO),
        RENTA_ALQ = sum(RENTA_ALQ),
        PAR150 = sum(PAR150),
        PATINMO = sum(PATINMO),
        FACTORCAL = mean(FACTORCAL),
        CCAA = mean(CCAA),
        PROV = mean(PROV),
        MUNI = mean(MUNI)
    ),
    by = .(reference = get(ref_unit))
]

# Rename the reference column to match 'ref_unit'
setnames(dt, "reference", as.character(ref_unit))

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

# Get the unique age groups from the sample data
unique_age_groups <- unique(dt$age_group)

# Subset the population margin to include only age groups present in the sample
age_distribution <- age_distribution[age_group %in% unique_age_groups]

# Now proceed with the raking process
raked_design <- rake(
  design = survey_design,
  sample.margins = list(~age_group, ~gender),
  population.margins = list(age_distribution, gender_distribution)
)

# Check the new raked weights
raked_weights <- weights(raked_design)
print(raked_weights)

# Example analysis: Weighted mean of income after raking
weighted_mean_income <- svymean(~RENTAD, raked_design)
print(weighted_mean_income)
