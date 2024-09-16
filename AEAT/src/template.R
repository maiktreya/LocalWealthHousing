# Rscript for Resampling Segovia
library("magrittr")
library("data.table")
library("survey")
rm(list = ls()) # Clean environment to avoid RAM bottlenecks

ref_survey <- "IEF" # Either IEF or EFF
ref_unit <- "IDENPER" # Use either IDENPER for personal or IDENHOG for household levels
selected_columns <- c("RENTAD", "RENTAB", "RENTA_ALQ", "PATINMO")

# Import chosen dataframe (change string according to the data file path)
dt <- fread("LocalWealthHousing/AEAT/data/IEF-2021-new.gz") # from IEAT IRPF sample
fr <- fread("LocalWealthHousing/AEAT/data/ief2021/pob-segovia.csv") # from INE population distribution

# Process the population data (assuming the first row contains overall totals)
sex <- fr[1, .(age, segoT, segoH, segoM)]
fr <- fr[-1, .(age, segoT, segoH, segoM)]

fr[, age_group := cut(as.numeric(age), breaks = seq(0, 110, by = 12), right = FALSE)]

# Summarize the population by age group
age_distribution <- fr[, .(Freq = sum(segoT) / sum(sex$segoT)), by = age_group]

gender_distribution <- data.table(
    gender = c("male", "female"),
    Freq = c(sex$segoH / sex$segoT, sex$segoM / sex$segoT)
)

# Replace NA values with 0 in selected columns
dt[, (selected_columns) := lapply(.SD, function(x) ifelse(is.na(x), 0, x)), .SDcols = selected_columns]

# Main data transformation: Filter rows and summarize
dt[TRAMO == "N", TRAMO := 8][, TRAMO := as.numeric(TRAMO)]

# Identify towns to analyze
dt[CCAA == "7" & PROV == "40" & MUNI == "194", segovia := 1]

dt <- dt[TIPODEC %in% c("T1", "T21") & !is.na(FACTORCAL),
    .(
        IDENHOG = mean(IDENHOG),
        segovia = mean(segovia),
        SEXO = mean(SEXO), # 1 = Male, 2 = Female
        age = 2022 - mean(ANONAC), # Calculate age
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
dt[, age_group := cut(age, breaks = seq(0, 110, by = 12), right = FALSE)]

# Remove rows with missing age groups (or impute missing values if needed)
dt <- dt[!is.na(age_group)]

# Restrict the survey to the city of interest
dt_sg <- subset(dt, segovia == 1)

# Create the survey design object with the initial weights
survey_design <- svydesign(
    ids = ~1,
    data = dt_sg,
    weights = dt_sg$FACTORCAL
) # Initial survey design with elevation factors

# Get the unique age groups from the sample data
unique_age_groups <- unique(dt_sg$age_group)

# Subset the population margin to include only age groups present in the sample
age_distribution2 <- age_distribution[age_group %in% unique_age_groups]


# Proceed with the raking process
raked_design <- rake(
    design = survey_design,
    sample.margins = list(~age_group, ~gender),
    population.margins = list(age_distribution2, gender_distribution),
    control = list(maxit =10, epsilon = 1, verbose=FALSE)
)

# Rescale the raked weights to match Segovia's total population
total_population_segovia <- sum(sex$segoT)
raked_weights <- raked_design$variables[, "FACTORCAL"]
rescaled_weights <- raked_weights * (total_population_segovia / sum(raked_weights))

raked_design <- update(raked_design, weights = rescaled_weights)

svymean(~RENTAD, raked_design2) %>% print()
