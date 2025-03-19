# Anexo Metodológico

El presente anexo pretende facilitar replicar en la medida de lo posible los datos obtenidos en este informe para otros municipios enfrentando un mercado del alquiler problemático. Dadas las limitaciones existentes en la disponibilidad de datos, para poder obtener toda la información a presentar es muy recomendable que el municipio a analizar tenga una población superior a los 50.000 habitantes o, idealmente, que se trate de una capital de provincia.

Para facilitar este proceso se ha creado un repositorio público desde el que poder reproducir nuestros resultados o ampliarlos a otas unidades geográficas:

https://github.com/maiktreya/LocalWealthHousing

Existen dos importantes limitaciones en este proceso:
- Heterogeneidad en la disponibilidad y acceso a fuentes primarias elaboradas por las administraciones local y autonómica.
- Especificidad del caso de Segovia (tanto el importante foco en el sector turístico como la elaboración de las encuestas a estudiantes universitarios responde a las necesidades concretas de la ciudad de Segovia y con total seguridad son características innecesarias a la hora de analizar otras realidades municipales).
### TABLAS DEL INE
---
**DATOS DEMOGRAFICOS**
- Censo de Población y Viviendas (2011, 2021)
- Encuesta Continua Características de los Hogares (2016)

La práctica totalidad de los datos demográficos utilizados en este informe procede de estas dos encuestas proporcionadas por el INE. Para acceder a estos datos con mayor facilidad puede utilizarse la API provista a tal efecto. Una integración básica junto al listado exhaustivo de las tablas referenciadas para la elaboración de este informe puede encontrarse en el siguiente script de nuestro repositorio:

**DATOS AFLUENCIA TURISTICA Y CAPACIDAD HOSTELERA**
- Encuesta de ocupación en Alojamientos Turísticos extra-hoteleros (2011-)
- Encuesta de Ocupación Hotelera (2004-)
- Estadística experimental. Ocupación en alojamientos turísticos (2018-)
- Estadística experimental. Medición del número de viviendas turísticas en  España y su capacidad. (2018-)

### EXPLOTACIÓN MUESTRA IRPF AGENCIA TRIBUTARIA

**CALIBRACIÓN Y REPRESENTATIVIDAD MUNICIPAL**
La muestra de IRPF facilitada por la AEAT garantiza la representatividad a nivel autonómico, pero no a la escala municipal. Para garantizar unos resultados robustos hemos sometido a la submuestra de hogares de Segovia un proceso de re-calibración de los pesos muestrales teniendo en cuenta los estratos originales utilizados y sus proporciones poblacionales a escala municipal obtenidos mediante los datos del Censo de Población y Viviendas (2011, 2021) o la Encuesta Continua de Hogares (2013-).

No tiene sentido entrar en el detalle estadístico de este procedimiento, simplemente indicar que el proceso está detallado en su totalidad en el siguiente documento del repositorio base: 

https://github.com/maiktreya/LocalWealthHousing/blob/main/md/analisis-datos.md

Es importante tener en cuenta que la muestra de IRPF no se encuentra disponible públicamente sino que requiere de solicitud formal de los mismos a la AEAT.

**CONSTRUCCIÓN DE VARIABLES SOBRE INGRESOS Y RENTISMO**

---

### EXPLOTACIÓN DE INFORMACIÓN DE PLATAFORMAS PRIVADAS
**OBTENCIÓN DE DATOS HISTÓRICOS**
> ALQUILER & VENTA  -> https://www.idealista.com/sala-de-prensa/informes-precio-vivienda/
> ALQUILER -> INE (Índice Precios Vivienda en Alquiler)

Para obtener datos históricos sobre el precio medio del m2 tanto en el mercado de compra-venta como el del alquiler, podemos utilizar dos vías alternativas (para municipios capital de provincia)

**SCRAPPING COMPLETO DEL MERCADO INMOBILIARIO**
> REPOSITORIO AIRBNB & IDEALISTA -> https://github.com/maiktreya/rental-scrapers

Para obtener información completa sobre el mercado de compra o alquiler (listado de propiedades, localización, precio...) podemos utilizar herramientas denominadas scrappers

Airbnb (pisos turísticos)
Idealista (mercados de compra y alquiler)

### OTROS
  Viviendas alquiler social ayuntamiento y CCAA
  Número de viviendas vendidas (ministerio sostenibilidad) -> https://apps.fomento.gob.es/BoletinOnline2/sedal/34010210.XLS



● INE



● UVA
○ Informes sobre tendencias turísticas (2016, 2022)
● Ayuntamiento Segovia
○ Informes Observatorio Turístico (Empresa Municipal de Turismo)
○ Visitantes CRV (Empresa Municipal de Turismo)
● AEAT
○ Panel de IRPF (2016, 2021)
● JCyL
○ Número de estudiantes IE/UVA (2011-2024)
○ Número de viviendas en alquiler por parte de Junta/Diputación (2024)















## Replicación de calculos para otros municipios

- Limitaciones: tamaño del municipio
- Elavoraciónes particulares: encuesta de estudiantes




### HOGARES

- Datos poblacionales


- Datos económicos 


### 