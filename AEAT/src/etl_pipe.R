# Rscript for Resampling Segovia
library("data.table")
rm(list = ls()) # clean enviroment to avoid ram bottlenecks

# Use either IDENPER for personal or IDENHOG for household level
sel_year <- 2016
ref_unit <- "IDENHOG"
selected_columns <- c("RENTAD", "RENTAB", "RENTA_ALQ", "PATINMO", "PAR150")

# Import chosen dataframe (change string according to the data file path)
dt <- fread(paste0("AEAT/data/IEF-", sel_year, "-new.gz")) # from IEAT IRPF sample

# Replace NA values with 0 in selected columns
dt[, (selected_columns) := lapply(.SD, function(x) ifelse(is.na(x), 0, x)), .SDcols = selected_columns]

# Main data transformation: Filter rows and summarize
dt[TRAMO == "N", TRAMO := 8][, TRAMO := as.numeric(TRAMO)]

# Identify towns to analyze
dt[, MUESTRA := 0] # add a column for the subsample identifier
dt[CCAA == "7" & PROV == "40" & MUNI == "194", MUESTRA := 1] # segovia
dt[CCAA == "7" & PROV == "40" & MUNI == "112", MUESTRA := 2] # lastrilla
dt[CCAA == "7" & PROV == "40" & MUNI == "906", MUESTRA := 3] # sancris
dt[CCAA == "7" & PROV == "40" & MUNI == "155", MUESTRA := 4] # palazuelos

dt <- dt[!is.na(FACTORCAL),
    .(
        MIEMBROS = uniqueN(IDENPER),
        IDENHOG = mean(IDENHOG),
        SEXO = mean(SEXO), # 1 = Male, 2 = Female
        AGE = (sel_year + 1) - mean(ANONAC), # Calculate age
        RENTAB = sum(RENTAB),
        RENTAD = sum(RENTAD),
        TRAMO = mean(TRAMO),
        RENTA_ALQ = sum(RENTA_ALQ),
        PAR150 = sum(PAR150),
        PATINMO = sum(PATINMO),
        FACTORCAL = mean(FACTORCAL),
        CCAA = mean(CCAA),
        PROV = mean(PROV),
        MUNI = mean(MUNI),
        MUESTRA = mean(MUESTRA)
    ),
    by = .(reference = get(ref_unit))
]

# Rename the reference column to match 'ref_unit'
ifelse(ref_unit == "IDENHOG",
    dt <- dt[, -c("reference")],
    setnames(dt, "reference", as.character(ref_unit))
)

# Define any new categorical variable before setting the survey object
dt[, TENENCIA := "INQUILINA"]
dt[PAR150 > 0, TENENCIA := "CASERO"]
dt[PATINMO > 0 & TENENCIA != "CASERO", TENENCIA := "PROPIETARIO"]
dt[, TENENCIA := factor(TENENCIA)]
dt[, RENTAD_NOAL := 0][, RENTAD_NOAL := RENTAD - RENTA_ALQ]
