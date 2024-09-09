# rscript resampling segovia
library("magrittr")
library("data.table")
library("survey")
rm(list = ls()) # clean enviroment to avoid ram bottlenecks

ref_survey <- "IEF" # either IEF or EFF
ref_unit <- "IDENPER" # Use either IDENPER for personal or IDENHOG for household levels
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

# identificar municipios a analizar
dt[CCAA == "7" & PROV == "40" & MUNI == "194", segovia := 1]
dt[CCAA == "7" & PROV == "40" & MUNI == "906", san_cristobal := 1]
dt[CCAA == "7" & PROV == "40" & MUNI == "155", palazuelos := 1]
dt[CCAA == "7" & PROV == "40" & MUNI == "112", la_lastrilla := 1]


# generar clase de ciudadanos (inquilinos)
dt[, CASERO := 0][PAR150 > 0, CASERO := 1][, CASERO := factor(CASERO)]
dt[, PROPIETARIO_SIN := 0][PATINMO > 0 & CASERO == 0, PROPIETARIO_SIN := 1][, PROPIETARIO_SIN := factor(PROPIETARIO_SIN)]
dt[, INQUILINO := 1][PROPIETARIO_SIN == 1, INQUILINO := 0][CASERO == 1, INQUILINO := 0][, INQUILINO := factor(INQUILINO)]
dt[, RENTAD_NOAL := 0][, RENTAD_NOAL := RENTAD - RENTA_ALQ]


