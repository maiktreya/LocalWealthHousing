# Anexo Metodológico

El presente anexo pretende facilitar replicar en la medida de lo posible los datos obtenidos en este informe para otros municipios enfrentando un mercado del alquiler problemático. Dadas las limitaciones existentes en la disponibilidad de datos, para poder obtener toda la información a presentar es muy recomendable que el municipio a analizar tenga una población superior a los 50.000 habitantes o, idealmente, que se trate de una capital de provincia.

Para facilitar este proceso se ha creado un repositorio público desde el que poder reproducir nuestros resultados o ampliarlos a otas unidades geográficas:

https://github.com/maiktreya/LocalWealthHousing

Existen dos importantes limitaciones en este proceso:
- Heterogeneidad en la disponibilidad y acceso a fuentes primarias elaboradas por las administraciones local y autonómica.
- Especificidad del caso de Segovia (tanto el importante foco en el sector turístico como la elaboración de las encuestas a estudiantes universitarios responde a las necesidades concretas de la ciudad de Segovia y con total seguridad son características innecesarias a la hora de analizar otras realidades municipales).

---
---

## Obtención de datos primaros

---

### TABLAS DEL INE
**DATOS DEMOGRAFICOS**
- Censo de Población y Viviendas (2011, 2021)
- Encuesta Continua Características de los Hogares (2016)

La práctica totalidad de los datos demográficos utilizados en este informe procede de estas dos encuestas proporcionadas por el INE. Para acceder a estos datos con mayor facilidad puede utilizarse la API provista a tal efecto. Una integración básica junto al listado exhaustivo de las tablas referenciadas para la elaboración de este informe puede encontrarse en el siguiente script de nuestro repositorio:

https://github.com/maiktreya/LocalWealthHousing/blob/main/INE/src/tablas-INE.R

En caso de querer analizar los datos a un nivel más granular, el INE pone a disposición pública los microdatos de los distintos releases de estas encuestas. Estas encuestas nos permiten obtener no solo la información demográfica referente a hogares sino también al número total de viviendas y su clasificación por tipo de uso.

**DATOS AFLUENCIA TURISTICA Y CAPACIDAD HOSTELERA**
- Encuesta de ocupación en Alojamientos Turísticos extra-hoteleros (2011-)
- Encuesta de Ocupación Hotelera (2004-)
- Estadística experimental. Ocupación en alojamientos turísticos (2018-)
- Estadística experimental. Medición del número de viviendas turísticas en  España y su capacidad. (2018-)

El análisis de la oferta hostelera y demanda turística descansa en dos encuestas analizando la capacidad y nivel de ocupación de los alojamientos hoteleros o de otro tipo respectivamente.

Más allá de los datos de estas encuestas el INE, consciente de la necesidad de capturar alojamientos que muchas veces no figuran registrados propiamente según su tipología, problema especialmente notorio en el caso de las Viviendas de Uso Turístico. Para superar esta limitación el INE ha elaborado dos estadísticas de caracter experimental que beben de la explotación mediante técnicas de scrapping de las principales plataformas web anunciantes de este tipo de alojamientos.

---

### EXPLOTACIÓN MUESTRA IRPF AGENCIA TRIBUTARIA

**CALIBRACIÓN Y REPRESENTATIVIDAD MUNICIPAL**
La muestra de IRPF facilitada por la AEAT garantiza la representatividad a nivel autonómico, pero no a la escala municipal. Para garantizar unos resultados robustos hemos sometido a la submuestra de hogares de Segovia un proceso de re-calibración de los pesos muestrales teniendo en cuenta los estratos originales utilizados y sus proporciones poblacionales a escala municipal obtenidos mediante los datos del Censo de Población y Viviendas (2011, 2021) o la Encuesta Continua de Hogares (2013-).

No tiene sentido entrar en el detalle estadístico de este procedimiento, simplemente indicar que el proceso está detallado en su totalidad en el siguiente documento del repositorio base: 

https://github.com/maiktreya/LocalWealthHousing/blob/main/md/analisis-datos.md

Es importante tener en cuenta que la muestra de IRPF no se encuentra disponible públicamente sino que requiere de solicitud formal de los mismos a la AEAT.

**CONSTRUCCIÓN DE VARIABLES SOBRE INGRESOS Y RENTISMO**

Para poder elaborar los datos económicos derivados de esta muestra, hemos definido las siguientes categorías de referencia:
- HOGAR RENTISTA:
- INGRESOS DEL HOGAR OBTENIDOS DEL ALQUILER DE VIVIENDAS:
- NÚMERO DE PROPIEDADES EN ALQUILER:
- HOGAR NO-PROPIETARIO: Aquel hogar 

---

### EXPLOTACIÓN DE INFORMACIÓN DE PLATAFORMAS PRIVADAS

**OBTENCIÓN DE DATOS HISTÓRICOS**
- ALQUILER & VENTA  -> https://www.idealista.com/sala-de-prensa/informes-precio-vivienda/
- ALQUILER -> INE (Índice Precios Vivienda en Alquiler)

Para obtener datos históricos sobre el precio medio del m2 tanto en el mercado de compra-venta como el del alquiler, podemos utilizar dos vías alternativas (para municipios capital de provincia)

**SCRAPPING COMPLETO DEL MERCADO INMOBILIARIO**
- REPOSITORIO AIRBNB & IDEALISTA -> https://github.com/maiktreya/rental-scrapers

Para obtener información completa sobre el mercado de compra o alquiler (listado de propiedades, localización, precio...) podemos utilizar herramientas denominadas scrappers.
1) Obtener datos de los mercados de compra y alquiler para un municipio determinado explotando la web de Idealista.
2) Obtener datos reales del número total de Viviendas de Uso Turístico ofertadas de manera efectiva explotando la web de AirBnB.

### OTROS
Existen otras fuentes auxiliares de importancia también utilizadas por este trabajo. Podemos dividirlas en tres grandes grupos. En el primer grupo incluimos aquellas que pueden obtenerse de manera homogenea para cualquier municipio destacamos:
- Número de viviendas vendidas (ministerio sostenibilidad) -> https://apps.fomento.gob.es/BoletinOnline2/sedal/34010210.XLS
Por otro lado, el otro grupo esta constituido por indicadores que aún teniendo un rol central en la elaboración del informe, se obtienen de manera heterogénea o no esta garantizada su disponibilidad al depender su elaboración de administraciones regionales. Principalmente:  
-Número de Viviendas en alquiler social. (Tanto a nivel municipal por parte del ayuntamiento, como autonómico por la CCAA correspondiente).
Por último, el tercer grupo de fuentes primarias utilizadas incluye aquellas variables con seguridad no reproducibles elaboradas por distinitos agentes sobre la realidad particular segoviana. Entre otros:
- Informes Observatorio Turístico (Empresa Municipal de Turismo. Ayto de Segovia)
- Visitantes CRV (Empresa Municipal de Turismo. Ayto de Segovia)
- Número de estudiantes IE/UVA (Junta de Castilla y León)

---
---

## Caractéristicas básicas de la encuesta sobre el coste del alojamiento en estudiantes universitarios