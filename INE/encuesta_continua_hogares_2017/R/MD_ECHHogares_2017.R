#################################################################################
# Nombre del programa:	MD_ECHHogares_2017.R
# Autor:              	INE
# Version:            	4.1
# �ltima modificaci�n: 	15 septiembre 2017
#
# Descripci�n:
# 	Este programa procesa un fichero de microdatos (md_ECHHogares_2017.txt)
#   a partir de un fichero de metadatos (dr_ECHHogares_2017.xlsx) que contiene
#   el dise�o de registro del archivo de microdatos.
#     ECHHogares.: Operaci�n estad�stica
#     2017: A�o(s) de producci�n de los datos
#
# Entrada:
#     - Dise�o de registro: 	dr_ECHHogares_2017.xlsx
#     - Archivo de microdatos: 	md_ECHHogares_2017.txt
# Salida:
#     - Archivo de microdatos en formato data.frame de R: fichero_salida
#
#################################################################################


assign("flag_num", 0, envir = .GlobalEnv)

atencion <- function(mensaje) {
  cat(mensaje)
  assign("flag_num", 1, envir = .GlobalEnv)
}
if (!"XLConnect" %in% installed.packages()) {
  install.packages("XLConnect")
}

library("XLConnect")

####################    Asignaci�n de par�metros    #######################

fichero_micro <- "INE/encuesta_continua_hogares_2017/md_ECHHogares_2017.txt"
fichero_meta <- "INE/encuesta_continua_hogares_2017/dr_ECHHogares_2017.xlsx"

####################     INICIO     #########################
start.time <- Sys.time()
cat("\n")
cat("\n Inicio: ")
print.Date(start.time)
t0 <- proc.time()

# Lectura del fichero de metadatos (METAD), Hoja "Dise�o" de archivo .xlsx
tryCatch((workBook <- loadWorkbook(fichero_meta)), error = function(e) {
  stop(paste("Error. No se puede abrir el fichero: ", e, fichero_meta, ". Saliendo de la ejecuci�n...", sep = ""))
})
df <- readNamedRegion(workBook, name = "METADATOS")

nombresVarbls <- df[, 1]
nombresTablas <- df[, 2]
posiciones <- df[, 3]
tipo <- df[, 4]
tamanio <- length(nombresVarbls)

# Lectura del fichero de microdatos (MICROD)
if (length(df) == 4) {
  cat("Sin formato")

  # Capturamos las columnas con su tipo de dato
  tipDatos <- as.vector(sapply(df[, 4], function(x) {
    if (identical(x, "A")) {
      "character"
    } else {
      if (identical(x, "N")) {
        "numeric"
      }
    }
  }))
  # Lectura del fichero de microdatos (MICROD), decimales con punto en MD
  tryCatch((df1 <- read.fwf(file = fichero_micro, widths = posiciones, colClasses = tipDatos)), error = function(e) {
    stop(paste("Error. No se encuentra el fichero: ", e, fichero_micro, ". Saliendo de la ejecuci�n...", sep = ""))
  })
} else {
  formatos <- df[, 5]
  cat("Con formato")

  # Lectura del fichero de microdatos (MICROD), decimales sin punto en MD
  tryCatch((df1 <- read.fortran(file = fichero_micro, format = formatos)), error = function(e) {
    stop(paste("Error. No se encuentra el fichero: ", e, fichero_micro, ". Saliendo de la ejecuci�n...", sep = ""))
  })
}

# Aplicamos los nombres de la cabecera del registro
names(df1) <- df[, 1]
fichero_salida <- df1


# Liberacion de memoria y aclaraci�n de variables
# Values
rm(flag_num, workBook, nombresVarbls, nombresTablas, posiciones, tamanio, df, df1)
if (length(df) == 4) {
  rm(tipDatos)
}


# Mensaje final ##########################################
end.time <- Sys.time()
cat("\n")
cat("\n Fin del proceso de lectura: ")
print.Date(end.time)

TTotal <- proc.time() - t0
tiempo <- TTotal[3]

if (tiempo < 60) {
  cat(paste("\n Tiempo transcurrido:", format(round(tiempo, 2), nsmall = 2), "segundos"))
} else {
  if (tiempo < 3600 & tiempo >= 60) {
    cat(paste("\n Tiempo transcurrido:", format(round(tiempo / 60, 2), nsmall = 2), "minutos"))
  } else {
    cat(paste("\n Tiempo transcurrido:", format(round(tiempo / 3600, 2), nsmall = 2), "horas"))
  }
}
