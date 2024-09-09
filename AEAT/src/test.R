# rscript resampling segovia
library("magrittr")
library("data.table")
library("survey")
rm(list = ls()) # clean enviroment to avoid ram bottlenecks

ref_survey <- "IEF" # either IEF or EFF
sel_year <- 2020 # 2020 for EFF & 2021 for IEF
ref_unit <- "IDENHOG" # Use either IDENPER for personal or IDENHOG for household levels
selected_columns <- c("RENTAD", "RENTA_ALQ", "PATINMO")

# Import choosen dataframe (cambiar string inicial según ruta de los datos)
dt <- fread("LocalWealthHousing/AEAT/data/IEF-2021-new.gz")

# Use lapply with .SDcols to specify columns and replace NA with 0
dt[, (selected_columns) := lapply(.SD, function(x) ifelse(is.na(x), 0, x)), .SDcols = selected_columns]

# Main data transformation TABLA[ filter_rows , select_columns  , group_by ]
    dt[TRAMO == "N", TRAMO := 8][, TRAMO := as.numeric(TRAMO)]

    dt <- dt[TIPODEC %in% c("T1", "T21") & !is.na(FACTORCAL),
        .(
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
    setnames(dt, "reference", as.character(ref_unit))


print(colnames(dt))

segovia <- dt[CCAA == "7" & PROV == "40" & MUNI == "194"]
san_cristobal <- dt[CCAA == "7" & PROV == "40" & MUNI == "906"]
palazuelos <- dt[CCAA == "7" & PROV == "40" & MUNI == "155"]
la_lastrilla <- dt[CCAA == "7" & PROV == "40" & MUNI == "112"]

print(nrow(segovia))
print(nrow(san_cristobal))
print(nrow(palazuelos))
print(nrow(la_lastrilla))
