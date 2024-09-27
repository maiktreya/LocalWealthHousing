# Obtain t-statisctics for representative mean for AEAT subsample

rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
source("AEAT/src/transform/etl_pipe.R")

# define city subsample and variables to analyze
city <- "madrid"
represet <- "!is.na(FACTORCAL)" # población
sel_year <- 2016
ref_unit <- "IDENHOG"
pop_stats <- fread("AEAT/data/pop-stats.csv")
age_vector <- fread("AEAT/data/madrid-age-freq.csv")[, .(age_group, freq=get(paste0("freq",sel_year)))]
sex_vector <- fread("AEAT/data/madrid-sex-freq.csv")[, .(gender, freq=get(paste0("freq",sel_year)))]
RNpop <- pop_stats[muni == city & year == sel_year, get(paste0("RN_", tolower(ref_unit)))]
RBpop <- pop_stats[muni == city & year == sel_year, get(paste0("RB_", tolower(ref_unit)))]
dt <- get_wave(sel_year = sel_year, ref_unit = ref_unit, represet = represet)


dt[, gender := "female"][SEXO == 1, gender := "male"]
dt[, age_group := cut(
    AGE,
    breaks = seq(0, 105, by = 5), # Adjusting the upper limit to 105 to cover "100 y más años"
    right = FALSE,
    labels = c(1:21),
    include.lowest = TRUE # Ensures the lowest interval includes the lower bound
)]

# Define raking margins
margins <- list(
    ~gender,  # Rake by gender
    ~age_group  # Rake by sex
)

# Population proportions for raking
pop_totals <- list(
    sex_vector,
    age_vector  # Use the male/female proportions as a data.frame
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

# Test sample means against true population means using svycontrast
RNmean <- svymean(~RENTAD, subsample)
RBmean <- svymean(~RENTAB, subsample)

# Test if the survey means are equal to the population means
test_rep1 <- svycontrast(RNmean, quote(RENTAD - RNpop)) %>% print()
test_rep2 <- svycontrast(RBmean, quote(RENTAB - RBpop)) %>% print()

# Summarize the results
net_vals <- data.table(pop = RNpop,
 mean = coef(RNmean),
se = SE(RNmean),
dif = (RNpop - coef(RNmean)) / RNpop)

gross_vals <- data.table(pop = RBpop,
 mean = coef(RBmean),
  se = SE(RBmean),
  dif = (RBpop - coef(RBmean)) / RBpop)
results <- rbind(net_vals, gross_vals, use.names = FALSE) %>% print()
