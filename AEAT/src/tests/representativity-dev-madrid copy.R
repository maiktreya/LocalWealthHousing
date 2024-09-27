# Obtain t-statistics for representative mean for AEAT subsample

rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")

# Define city subsample and variables to analyze
city <- "madrid"
represet <- "!is.na(FACTORCAL)" # población
sel_year <- 2016
ref_unit <- "IDENHOG"
pop_stats <- fread("AEAT/data/pop-stats.csv")
age_vector <- fread("AEAT/data/madrid-age-freq.csv")[, .(age_group, freq = get(paste0("freq", sel_year)))]
sex_vector <- fread("AEAT/data/madrid-sex-freq.csv")[, .(gender, freq = get(paste0("freq", sel_year)))]
RNpop <- pop_stats[muni == city & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]
RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]
dt <- get_wave(sel_year = sel_year, ref_unit = ref_unit, represet = represet)

# Adjust gender and age_group
dt[, gender := "female"][SEXO == 1, gender := "male"]
# Collapse age groups into 4 broader categories
dt[, age_group := cut(
    AGE,
    breaks = c(0, 18, 35, 65, Inf),  # Defining age group breaks: 0-18, 19-35, 36-65, 66+ 
    labels = c("0-18", "19-35", "36-65", "66+"),
    right = FALSE,
    include.lowest = TRUE
)]

# Collapse age_vector to match the new age groups
age_vector <- fread("AEAT/data/madrid-age-freq.csv")[, .(age_group, freq = get(paste0("freq", sel_year)))]

# Define new age group categories in age_vector to match the sample
age_vector[, age_group := cut(
    as.integer(age_group), 
    breaks = c(0, 18, 35, 65, Inf),
    labels = c("0-18", "19-35", "36-65", "66+"),
    right = FALSE,
    include.lowest = TRUE
)]
dt <- dt[!is.na(age_group)]

# Aggregate frequencies for the collapsed age groups
age_vector <- age_vector[, .(freq = sum(freq)), by = age_group]

# Ensure population margins don't include categories absent in the sample
age_vector <- age_vector[age_group %in% unique(dt$age_group)]
sex_vector <- sex_vector[gender %in% unique(dt$gender)]

# Define raking margins
margins <- list(
    ~gender,  # Rake by gender
    ~age_group  # Rake by the collapsed age_group
)

# Population proportions for raking
pop_totals <- list(
    sex_vector,
    age_vector  # Use the filtered male/female proportions as a data.frame
)

# Prepare survey object from dt and set income cuts for quantiles dynamically
dt_sv <- svydesign(ids = ~1, data = dt, weights = dt$FACTORCAL) # muestra con coeficientes de elevación
pre_subsample <- subset(dt_sv, CCAA == "13" & PROV == "28" & MUNI == "79")

# Apply raking
subsample <- rake(
    design = pre_subsample,
    sample.margins = margins,
    population.margins = pop_totals
)
