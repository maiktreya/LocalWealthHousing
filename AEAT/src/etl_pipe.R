# Rscript for transforming base AEAT sample files from their tax record sample

# Use either IDENPER for personal or IDENHOG for household level

get_wave <- function(sel_year = 2016, ref_unit = "IDENHOG", represet = "!is.na(FACTORCAL)") {
    # Load required libraries

    library(data.table, quietly = TRUE)

    sel_cols <- c("RENTAD", "RENTAB", "RENTA_ALQ", "PATINMO", "REFCAT", "INCALQ", "PAR150i")

    # Import chosen dataframe (change string according to the data file path)

    dt <- fread(paste0("AEAT/data/IEF-", sel_year, "-new.gz")) # from IEAT IRPF sample

    # Replace NA values with 0 in selected columns

    dt[, (sel_cols) := lapply(.SD, function(x) ifelse(is.na(x), 0, x)), .SDcols = sel_cols]

    # Coerce conflicting values of var TRAMO to numeric

    dt[TRAMO == "N", TRAMO := 8][, TRAMO := as.numeric(TRAMO)]

    # Identify towns to analyze

    dt[, MUESTRA := 0] # add a column for the subsample identifier
    dt[CCAA == "7" & PROV == "40" & MUNI == "194", MUESTRA := 1] # segovia
    dt[CCAA == "7" & PROV == "40" & MUNI == "112", MUESTRA := 2] # lastrilla
    dt[CCAA == "7" & PROV == "40" & MUNI == "906", MUESTRA := 3] # sancris
    dt[CCAA == "7" & PROV == "40" & MUNI == "155", MUESTRA := 4] # palazuelos
    dt[CCAA == "13" & PROV == "28" & MUNI == "079", MUESTRA := 5] # madrid
    dt[, RENTA_ALQ2 := 0][PAR150i > 0, RENTA_ALQ2 := INCALQ] # solo ingresos del alquiler de vivienda

    # tidy dt for the given reference unit through in-place vectorized operations

    dt <- dt[eval(parse(text = represet)),
        .(
            MIEMBROS = uniqueN(IDENPER),
            NPROP_ALQ = uniqueN(REFCAT),
            IDENHOG = mean(IDENHOG),
            SEXO = mean(SEXO), # 1 = Male, 2 = Female
            AGE = (sel_year + 1) - mean(ANONAC), # Calculate age
            RENTAB = sum(RENTAB),
            RENTAD = sum(RENTAD),
            TRAMO = mean(TRAMO),
            RENTA_ALQ = sum(RENTA_ALQ),
            RENTA_ALQ2 = sum(RENTA_ALQ2),
            PAR150 = sum(PAR150i),
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

    if (ref_unit == "IDENHOG") {
        dt <- dt[, -c("reference")]
    } else {
        setnames(dt, "reference", as.character(ref_unit))
    }

    # Define any new categorical variable before setting the survey object

    dt[, TENENCIA := "INQUILINA"]
    dt[PAR150 > 0, TENENCIA := "CASERO"]
    dt[PATINMO > 0 & TENENCIA != "CASERO", TENENCIA := "PROPIETARIO"]
    dt[, TENENCIA := factor(TENENCIA)]

    dt[, CASERO := 0][PAR150 > 0, CASERO := 1][, CASERO := factor(CASERO)]
    dt[, PROPIETARIO_SIN := 0][PATINMO > 0 & CASERO == 0, PROPIETARIO_SIN := 1][, PROPIETARIO_SIN := factor(PROPIETARIO_SIN)]
    dt[, INQUILINO := 1][PROPIETARIO_SIN == 1, INQUILINO := 0][CASERO == 1, INQUILINO := 0][, INQUILINO := factor(INQUILINO)]

    dt[, RENTAD_NOAL := 0][, RENTAD_NOAL := RENTAD - RENTA_ALQ2]

    # Return the final dt object
    return(dt)
}
