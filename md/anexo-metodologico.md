# Anexo Metodológico

El presente anexo pretende facilitar replicar en la medida de lo posible los datos obtenidos en este informe para otros municipios enfrentando un mercado del alquiler problemático. Dadas las limitaciones existentes en la disponibilidad de datos, para poder obtener toda la información a presentar, es muy recomendable que el municipio a analizar tenga una población superior a los 50.000 habitantes o, idealmente, que se trate de una capital de provincia.

Para facilitar este proceso se ha creado un repositorio público desde el que poder reproducir nuestros resultados o ampliarlos a otras unidades geográficas:

[Repositorio GitHub](https://github.com/maiktreya/LocalWealthHousing)

Existen dos importantes limitaciones en este proceso:
- Heterogeneidad en la disponibilidad y acceso a fuentes primarias elaboradas por las administraciones local y autonómica.
- Especificidad del caso de Segovia: tanto el importante foco en el sector turístico como la elaboración de las encuestas a estudiantes universitarios responden a las necesidades concretas de la ciudad de Segovia y con total seguridad son características que podrían no ser necesarias a la hora de analizar otras realidades municipales.

---
---

## Obtención de datos primarios

### TABLAS DEL INE
---

**DATOS DEMOGRÁFICOS**
- Censo de Población y Viviendas (2011, 2021)
- Encuesta Continua de Características de los Hogares (2016)

La práctica totalidad de los datos demográficos utilizados en este informe procede de estas dos encuestas proporcionadas por el INE. Para acceder a estos datos con mayor facilidad puede utilizarse la API provista a tal efecto. Una integración básica junto al listado exhaustivo de las tablas referenciadas para la elaboración de este informe puede encontrarse en el siguiente script de nuestro repositorio:

[Script de Tablas INE](https://github.com/maiktreya/LocalWealthHousing/blob/main/INE/src/tablas-INE.R)

En caso de querer analizar los datos a un nivel más granular, el INE pone a disposición pública los microdatos de los distintos releases de estas encuestas. Estas encuestas nos permiten obtener no solo la información demográfica referente a hogares sino también al número total de viviendas y su clasificación por tipo de uso.

**DATOS DE AFLUENCIA TURÍSTICA Y CAPACIDAD HOSTELERA**
- Encuesta de ocupación en Alojamientos Turísticos extra-hoteleros (2011-)
- Encuesta de Ocupación Hotelera (2004-)
- Estadística experimental. Ocupación en alojamientos turísticos (2018-)
- Estadística experimental. Medición del número de viviendas turísticas en España y su capacidad (2018-)

El análisis de la oferta hostelera y demanda turística descansa en dos encuestas que analizan la capacidad y nivel de ocupación de los alojamientos hoteleros o de otro tipo respectivamente.

Más allá de los datos de estas encuestas, el INE, consciente de la necesidad de capturar alojamientos que muchas veces no figuran registrados propiamente según su tipología (problema especialmente notorio en el caso de las Viviendas de Uso Turístico), ha elaborado dos estadísticas de carácter experimental que se nutren de la explotación mediante técnicas de scraping de las principales plataformas web anunciantes de este tipo de alojamientos.

### EXPLOTACIÓN MUESTRA IRPF AGENCIA TRIBUTARIA
---

**CALIBRACIÓN Y REPRESENTATIVIDAD MUNICIPAL**

La muestra de IRPF facilitada por la AEAT garantiza la representatividad a nivel autonómico, pero no a la escala municipal. Para garantizar unos resultados robustos hemos sometido a la submuestra de hogares de Segovia a un proceso de re-calibración de los pesos muestrales teniendo en cuenta los estratos originales utilizados y sus proporciones poblacionales a escala municipal obtenidos mediante los datos del Censo de Población y Viviendas (2011, 2021) o la Encuesta Continua de Hogares (2013-).

No tiene sentido entrar en el detalle estadístico de este procedimiento; simplemente indicar que el proceso completo, incluyendo el código y las técnicas de recalibración utilizadas, está detallado en su totalidad en el siguiente documento del repositorio base: 

[Análisis de tablas INE](https://github.com/maiktreya/LocalWealthHousing/blob/main/INE/src/tablas-INE.R)

Es importante tener en cuenta que la muestra de IRPF no se encuentra disponible públicamente sino que requiere de solicitud formal de los mismos a la AEAT.

**CONSTRUCCIÓN DE VARIABLES SOBRE INGRESOS Y RENTISMO**

Para poder elaborar los datos económicos derivados de esta muestra, hemos definido las siguientes categorías de referencia:

- HOGAR RENTISTA: Aquel hogar cuyos ingresos procedentes del alquiler de viviendas representan al menos un 30% de los ingresos totales.
- INGRESOS DEL HOGAR OBTENIDOS DEL ALQUILER DE VIVIENDAS: Suma total de ingresos declarados procedentes del arrendamiento de bienes inmuebles destinados a vivienda.
- NÚMERO DE PROPIEDADES EN ALQUILER: Número total de viviendas distintas de la vivienda habitual que generan ingresos por arrendamiento.
- HOGAR NO-PROPIETARIO: Aquel hogar que no posee ninguna vivienda en propiedad y reside en régimen de alquiler o cesión.

### EXPLOTACIÓN DE INFORMACIÓN DE PLATAFORMAS PRIVADAS
---

**OBTENCIÓN DE DATOS HISTÓRICOS**
- Alquiler y Venta: [Idealista](https://www.idealista.com/sala-de-prensa/informes-precio-vivienda/)
- Alquiler: INE (Índice de Precios de Vivienda en Alquiler)

Para obtener datos históricos sobre el precio medio del m² tanto en el mercado de compra-venta como el del alquiler, podemos utilizar dos vías alternativas (para municipios capital de provincia).

**SCRAPING COMPLETO DEL MERCADO INMOBILIARIO**
- Repositorio Airbnb & Idealista: [GitHub Rental Scrapers](https://github.com/maiktreya/rental-scrapers)

Para obtener información completa sobre el mercado de compra o alquiler (listado de propiedades, localización, precio...) podemos utilizar herramientas denominadas scrapers:
1. Obtener datos de los mercados de compra y alquiler para un municipio determinado explotando la web de Idealista.
2. Obtener datos reales del número total de Viviendas de Uso Turístico ofertadas de manera efectiva explotando la web de AirBnB.

### OTRAS FUENTES DE INFORMACIÓN

Existen otras fuentes auxiliares de importancia también utilizadas en este trabajo. Podemos dividirlas en tres grandes grupos:

**1. Fuentes disponibles de manera homogénea para cualquier municipio:**
- Número de viviendas vendidas (Ministerio de Transportes, Movilidad y Agenda Urbana): [Boletín Online](https://apps.fomento.gob.es/BoletinOnline2/sedal/34010210.XLS)

**2. Indicadores con disponibilidad heterogénea según administraciones regionales:**
- Número de viviendas en alquiler social (tanto a nivel municipal por parte del ayuntamiento, como autonómico por la CCAA correspondiente).

**3. Fuentes específicas para el caso de Segovia no necesariamente reproducibles en otros municipios:**
- Informes del Observatorio Turístico (Empresa Municipal de Turismo, Ayuntamiento de Segovia)
- Visitantes al Centro de Recepción de Visitantes (CRV) (Empresa Municipal de Turismo, Ayuntamiento de Segovia)
- Número de estudiantes del IE/UVA (Junta de Castilla y León)

---
---

## Características básicas de la encuesta sobre el coste del alojamiento en estudiantes universitarios

La encuesta se diseñó para capturar información sobre las condiciones de alojamiento de los estudiantes universitarios en Segovia, incluyendo:
- Tipo de alojamiento (residencia, piso compartido, domicilio familiar, etc.)
- Coste mensual del alojamiento
- Características de la vivienda (tamaño, estado, equipamiento)
- Satisfacción con el alojamiento actual
- Dificultades encontradas en la búsqueda de vivienda
- Impacto del coste del alojamiento en la economía personal o familiar

La muestra incluyó estudiantes de los diferentes campus universitarios presentes en la ciudad (IE University y Universidad de Valladolid), estratificada por curso académico y titulación. El cuestionario completo y la metodología específica de muestreo pueden consultarse en el repositorio del proyecto.