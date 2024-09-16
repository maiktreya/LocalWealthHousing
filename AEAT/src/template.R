# Rscript for Resampling Segovia
library("magrittr")
library("data.table")
library("survey")
rm(list = ls()) # Clean environment to avoid RAM bottlenecks

ref_survey <- "IEF" # Either IEF or EFF
ref_unit <- "IDENHOG" # Use either IDENPER for personal or IDENHOG for household levels
selected_columns <- c("RENTAD", "RENTAB", "RENTA_ALQ", "PATINMO")

# Import chosen dataframe (change string according to the data file path)
dt <- fread("AEAT/data/IEF-2021-new.gz") # from IEAT IRPF sample

# Replace NA values with 0 in selected columns
dt[, (selected_columns) := lapply(.SD, function(x) ifelse(is.na(x), 0, x)), .SDcols = selected_columns]

# Main data transformation: Filter rows and summarize
dt[TRAMO == "N", TRAMO := 8][, TRAMO := as.numeric(TRAMO)]

# Identify towns to analyze
dt[CCAA == "7" & PROV == "40" & MUNI == "194", segovia := 1]
dt[CCAA == "7" & PROV == "40" & MUNI == "112", lastrilla := 1]
dt[CCAA == "7" & PROV == "40" & MUNI == "906", sancris := 1]
dt[CCAA == "7" & PROV == "40" & MUNI == "155", palazuelos := 1]

dt2 <- dt[!is.na(FACTORCAL),
    .(
        IDENHOG = mean(IDENHOG),
        segovia = mean(segovia),
        lastrilla = mean(lastrilla),
        sancris = mean(sancris),
        palazuelos = mean(palazuelos),
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
setnames(dt2, "reference", as.character(ref_unit))

# Restrict the survey to the city of interest
dt_sg <- subset(dt2, segovia == 1)
