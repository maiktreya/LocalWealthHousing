get_wave <- function(
    sel_year = 2016,
    ref_unit = "IDENHOG",
    represet = "!is.na(FACTORCAL)",
    sel_cols = c("RENTAD", "RENTAB", "RENTA_ALQ", "PATINMO", "REFCAT", "INCALQ", "PAR150i")) {

    library(data.table, quietly = TRUE)

    # Load data
    dt <- fread(paste0("AEAT/data/IEF-", sel_year, "-new.gz"))

    # Replace NA values with 0 in selected columns
    setnafill(dt, type = "const", fill = 0, cols = sel_cols)

    # Coerce TRAMO to numeric
    dt[TRAMO == "N", TRAMO := 8][, TRAMO := as.numeric(TRAMO)]

    # Assign sample identifier (MUESTRA)
    dt[, MUESTRA := fcase(
        CCAA == "7" & PROV == "40" & MUNI == "194", 1, # segovia
        CCAA == "7" & PROV == "40" & MUNI == "112", 2, # lastrilla
        CCAA == "7" & PROV == "40" & MUNI == "906", 3, # sancristobal
        CCAA == "7" & PROV == "40" & MUNI == "155", 4, # palazuelos
        CCAA == "13" & PROV == "28" & MUNI == "79", 5, # madrid
        default = 0
    )]

    # Calculate rental income
    dt[, RENTA_ALQ2 := fifelse(PAR150i > 0, INCALQ, 0)]

    # STEP 1: Summarize by person to avoid duplicating records for persons with multiple properties
    dt <- dt[, .(
        MIEMBROS = uniqueN(IDENPER),
        NPROP_ALQ = uniqueN(REFCAT),
        IDENHOG = first(IDENHOG),
        SEXO = first(SEXO),
        AGE = sel_year - mean(ANONAC),
        RENTAB = mean(RENTAB),
        RENTAD = mean(RENTAD),
        TRAMO = mean(TRAMO),
        RENTA_ALQ = mean(RENTA_ALQ),
        RENTA_ALQ2 = mean(RENTA_ALQ2),
        PAR150 = sum(PAR150i),
        PATINMO = mean(PATINMO),
        FACTORCAL = mean(FACTORCAL),
        CCAA = first(CCAA),
        PROV = first(PROV),
        MUNI = first(MUNI),
        MUESTRA = first(MUESTRA)
    ), by = .(IDENPER)]

    # STEP 2: Aggregate by reference unit
    dt <- dt[eval(parse(text = represet)), .(
        MIEMBROS = mean(MIEMBROS),
        NPROP_ALQ = mean(NPROP_ALQ),
        IDENHOG = first(IDENHOG),
        SEXO = first(SEXO),
        AGE = mean(AGE),
        RENTAB = sum(RENTAB),
        RENTAD = sum(RENTAD),
        TRAMO = mean(TRAMO),
        RENTA_ALQ = sum(RENTA_ALQ),
        RENTA_ALQ2 = sum(RENTA_ALQ2),
        PAR150 = sum(PAR150),
        PATINMO = sum(PATINMO),
        FACTORCAL = mean(FACTORCAL),
        CCAA = first(CCAA),
        PROV = first(PROV),
        MUNI = first(MUNI),
        MUESTRA = first(MUESTRA)
    ), by = .(reference = get(ref_unit))]

    # Rename column
    if (ref_unit == "IDENHOG") {
        dt[, reference := NULL]
    } else {
        setnames(dt, "reference", as.character(ref_unit))
    }

    # Define new categorical variables
    dt[, TENENCIA := fifelse(PAR150 > 0, "CASERO", fifelse(PATINMO > 0, "PROPIETARIO", "INQUILINA"))]
    dt[, CASERO := factor(fifelse(PAR150 > 0, 1, 0))]
    dt[, PROPIETARIO := factor(fifelse(PATINMO > 0 & CASERO == 0, 1, 0))]
    dt[, INQUILINO := factor(fifelse(PROPIETARIO == 1 | CASERO == 1, 0, 1))]
    dt[, RENTAD_NOAL := RENTAD - RENTA_ALQ2]


    # **Replace numeric MUESTRA with corresponding text labels**
    dt[, MUESTRA := fcase(
        MUESTRA == 1, "segovia",
        MUESTRA == 2, "lastrilla",
        MUESTRA == 3, "sancristobal",
        MUESTRA == 4, "palazuelos",
        MUESTRA == 5, "madrid",
        default = NA_character_
    )]

    # Return the final dt object
    return(dt)
}
