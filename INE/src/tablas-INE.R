# Listado de tablas base utilizadas para elaborar el informe del alquiler de la ciudad de Segovia
# import data.table and magrittr for data handling
library(data.table)
library(magrittr)

# clean and prepare enviroment
rm(list = ls())
gc(verbose = TRUE)
full_export <- FALSE

# definir una función para lanzar requests a la API del INE
get_ine <- function(id_tabla = NA, municipio = NA) {
    url <- paste0("https://servicios.ine.es/wstempus/js/ES/DATOS_TABLA/", as.character(id_tabla))
    dt <- jsonlite::fromJSON(url) %>%
        tidyr::unnest(cols = c(Data)) %>%
        as.data.table()
    dt <- dt[Nombre %like% as.character(municipio) & !(Nombre %like% "San")]
    return(dt)
}

if (full_export) {
    # base de datos de ventas de vivienda por municipios (Min transporte y sost)
    download.file("https://apps.fomento.gob.es/BoletinOnline2/sedal/34010210.XLS",
        destfile = "pventa.xls",
        mode = "wb"
    )
}

# Plazas, apartamentos, grados de ocupación y personal empleado por puntos turísticos (Encuesta de ocupación en Alojamientos Turísticos extra-hoteleros)
dt1 <- get_ine(2083, "Segovia")

# Viajeros y pernoctaciones por puntos turísticos (Encuesta de ocupación hotelera)
dt2 <- get_ine(2078, "Segovia")

# Establecimientos, plazas estimadas, grados de ocupación y personal empleado por puntos turísticos (Encuesta de ocupación hotelera)
dt3 <- get_ine(2076, "Segovia")

# Ocupación en alojamientos turísticos (Estadística Experimental)
dt4 <- get_ine(48427, "Segovia")

# Medición del número de viviendas turísticas en España y su capacidad (Estadística Experimental)
dt5 <- get_ine(39366, "Segovia")

# Viviendas familiares convencionales según tipo de vivienda y año de construcción (agregado) del edificio (Censo 2021)
dt6 <- get_ine(59527, "Segovia")

# Viviendas familiares convencionales según tipo de vivienda y superficie (Censo 2021)
dt7 <- get_ine(59528, "Segovia")

# Viviendas familiares principales convencionales según régimen de tenencia (Censo 2021)
dt8 <- get_ine(59529, "Segovia")

# Hogares según su tamaño por estructura del hogar (Censo 2021)
dt9 <- get_ine(59945, "Segovia")

# Índice de Precios de la Vivienda en Alquiler (IPVA). Base 2015
dt10 <- get_ine(59060, "Segovia")

# Índice de Precios de la Vivienda en Alquiler (IPVA) por distritos. Base 2015
dt11 <- get_ine(59061, "Segovia")

dt <- list(dt1, dt2, dt3, dt4, dt5, dt6, dt7, dt8, dt9, dt10, dt11)

dt %>% print()
