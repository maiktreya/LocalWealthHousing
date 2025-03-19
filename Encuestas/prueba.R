library(data.table)
library(magrittr)
library(jsonlite)

# dt1 <- fread("https://www.ine.es/jaxiT3/files/t/es/csv_bdsc/2078.csv")
# dt1 <- dt1[get(colnames(dt1)[1]) %like% "Segovia"]

get_ine <- function(id_tabla = NA, municipio = NA) {
    url <- paste0("https://servicios.ine.es/wstempus/js/ES/DATOS_TABLA/", id_tabla)
    dt <- fromJSON(url, flatten = TRUE) %>% as.data.table()
    dt <- dt[Nombre %like% as.character(municipio)]$Data %>% rbindlist()
    return(dt)
}

# Pernoctaciones
dt <- get_ine(2078, "Segovia")

# Establecimientos, plazas estimadas, grados de ocupación y personal empleado por puntos turísticos
dt <- get_ine(50902, "Segovia")

# Ocupación en alojamientos turísticos
dt <- get_ine(48427, "Segovia")

# Estadística experimental. Medición del número de viviendas turísticas en España y su capacidad
dt <- get_ine(39366, "Segovia")

dt %>% print()

date(date())