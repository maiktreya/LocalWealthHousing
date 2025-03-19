# import data.table and magrittr for data handling
library(data.table)
library(magrittr)

# definir una función para lanzar requests a la API del INE
get_ine <- function(id_tabla = NA, municipio = NA) {
    url <- paste0("https://servicios.ine.es/wstempus/js/ES/DATOS_TABLA/", as.character(id_tabla))
    dt <- jsonlite::fromJSON(url) %>%
        tidyr::unnest(cols = c(Data)) %>%
        as.data.table()
    dt <- dt[Nombre %like% as.character(municipio) & !(Nombre %like% "San")]
    return(dt)
}

# base de datos de ventas de vivienda por municipios (Min transporte y sost)
download.file("https://apps.fomento.gob.es/BoletinOnline2/sedal/34010210.XLS",
    destfile = "pventa.xls",
    mode = "wb"
)

# Plazas, apartamentos, grados de ocupación y personal empleado por puntos turísticos (Encuesta de ocupación en Alojamientos Turísticos extra-hoteleros)
dt <- get_ine(2083, "Segovia")

# Viajeros y pernoctaciones por puntos turísticos (Encuesta de ocupación hotelera)
dt <- get_ine(2078, "Segovia")

# Establecimientos, plazas estimadas, grados de ocupación y personal empleado por puntos turísticos (Encuesta de ocupación hotelera)
dt <- get_ine(2076, "Segovia")

# Ocupación en alojamientos turísticos (Estadística Experimental)
dt <- get_ine(48427, "Segovia")

# Medición del número de viviendas turísticas en España y su capacidad (Estadística Experimental)
dt <- get_ine(39366, "Segovia")

# Viviendas familiares convencionales según tipo de vivienda y año de construcción (agregado) del edificio (Censo 2021)
dt <- get_ine(59527, "Segovia")

# Viviendas familiares convencionales según tipo de vivienda y superficie (Censo 2021)
dt <- get_ine(59528, "Segovia")

# Viviendas familiares principales convencionales según régimen de tenencia (Censo 2021)
dt <- get_ine(59529, "Segovia")

# Hogares según su tamaño por estructura del hogar (Censo 2021)
dt <- get_ine(59945, "Segovia")

# Índice de Precios de la Vivienda en Alquiler (IPVA). Base 2015
dt <- get_ine(59060, "Segovia")

# Índice de Precios de la Vivienda en Alquiler (IPVA) por distritos. Base 2015
dt <- get_ine(59061, "Segovia")

dt %>% print()


