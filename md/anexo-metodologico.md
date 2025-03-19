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

Las encuesta recolectada entre los estudiantes de las dos universidades de Segovia (IE y UVA) 
---

### A) Diseño Muestral de la Encuesta

#### Poblaciones de Estudio

Tu estudio se centra en dos poblaciones universitarias distintas:

1. **IE (Instituto de Empresa)**
   - Población total: 3.923 estudiantes
   - Muestra obtenida: 51 estudiantes
   - Tasa de muestreo: aproximadamente 1,3% de la población total

2. **UVA (Universidad de Valladolid)**
   - Población total: 2.323 estudiantes
   - Muestra obtenida: 61 estudiantes
   - Tasa de muestreo: aproximadamente 2,6% de la población total

#### Tipo de Muestreo

- El muestreo es aleatorio simple con universos independientes entre las dos universidades.
- No se aplicó estratificación ni agrupamiento en el diseño muestral.
- Pesos muestrales como inversa de la probabilidad de selección (constante).

#### Sistema de Ponderación

Para asegurar que la muestra represente adecuadamente a la población total, se aplicaron ponderaciones:

- **Ponderación para IE**: total_pop_ie/nrow(dt_ie) = 3.923/51 ≈ 76,92
- **Ponderación para UVA**: total_pop_uv/nrow(dt_uv) = 2.323/61 ≈ 38,08

Estas ponderaciones se utilizaron en el análisis para "expandir" los resultados de la muestra a la población total, asegurando que las estimaciones sean representativas del conjunto de estudiantes.

#### Variable de Interés

La variable principal analizada fue:
- `how_much_do_you_pay_monthly_in_your_rental_contract`: importe mensual que pagan los estudiantes por su contrato de alquiler

#### Método de Recolección de Datos

1. Encuestas estructuradas anonimizadas (mix de recolección en persona y mediante formulario web)
2. Tratamiento de no respuesta mediante imputación multiple y bootstraping.
3. Normalización de resultados para tratamiento estadístico (coerción a numérico o factor).
4. Los datos se almacenaron en archivos Excel (con nombres "IE_final_imputed.xlsx" y "UVA_final_imputed.xlsx")

#### Consideraciones sobre el Diseño Muestral

1. **Representatividad**: El diseño utiliza ponderaciones para ajustar la representatividad de la muestra respecto a la población total.

2. **Estimación de Parámetros**: El uso de la librería `survey` permite incorporar correctamente el diseño muestral en la estimación de medias y errores estándar.

3. **Intervalos de Confianza**: Se calcularon intervalos de confianza al 95% para las estimaciones, lo que proporciona un rango plausible para los verdaderos valores poblacionales.

4. **Tamaño Muestral**: Aunque las muestras (51 y 61 estudiantes) representan porcentajes relativamente pequeños de las poblaciones totales, el análisis de potencia indica que son más que suficientes dado el gran tamaño del efecto observado.

Este diseño muestral, aunque simple, es apropiado para el objetivo de comparar los gastos de alquiler entre las dos poblaciones universitarias. La implementación correcta de ponderaciones y el uso de herramientas estadísticas adecuadas (como la librería `survey`) fortalecen la validez de las conclusiones obtenidas.


### B) Resumen de los Resultados sobre la variable de referencia 

Tu estudio comparó los gastos mensuales de alquiler entre estudiantes de dos universidades diferentes:

1. **IE (Instituto de Empresa):**
   - Gasto medio mensual: **1.098,80€**
   - Intervalo de confianza (95%): 1.003,43€ - 1.194,17€

2. **UVA (Universidad de Valladolid):**
   - Gasto medio mensual: **375,72€**
   - Intervalo de confianza (95%): 332,58€ - 418,85€

### C) Interpretación Estadística

#### Diferencia Significativa
La diferencia entre los gastos de alquiler es estadísticamente significativa y muy grande. Los estudiantes del IE pagan aproximadamente 2,9 veces más que los estudiantes de la UVA.

#### Tamaño del Efecto
- **Cohen's d = 19,75**
- Este es un tamaño de efecto extraordinariamente grande (los valores superiores a 0,8 ya se consideran "grandes").
- Significa que la diferencia observada es casi 20 desviaciones estándar, lo que es enorme.

#### Análisis de Potencia Estadística
- **Potencia = 1,0 (100%)**
- Esto significa que el estudio tiene un 100% de probabilidad de detectar la diferencia observada.
- Con un efecto tan grande, es prácticamente imposible no detectar esta diferencia.

#### Tamaño Muestral Adecuado
- Tamaño muestral mínimo requerido para una potencia del 80%: solo 3 estudiantes por grupo.
- Tamaños muestrales actuales (IE: 51, UVA: 61) son mucho mayores de lo necesario.
- Las muestras son más que adecuadas para la inferencia estadística.

### D) Explicación de por qué el Tamaño Muestral Mínimo es tan Pequeño

Quizás te sorprenda que el tamaño muestral mínimo sea tan pequeño (solo 3 estudiantes por grupo), especialmente cuando las fórmulas tradicionales sugieren valores de 300-400 estudiantes. Esto se debe a:

1. **La Magnitud de la Diferencia**
   - La diferencia entre los dos grupos es tan grande (723,08€) que se puede detectar incluso con muestras muy pequeñas.
   - Es como si estuviéramos comparando el peso de elefantes con el de ratones; no necesitaríamos muchos ejemplares para notar la diferencia.

2. **Diferentes Propósitos Estadísticos**
   - La fórmula tradicional (n = (Z²p(1-p))/E²) se usa para estimar una proporción con un margen de error específico.
   - El análisis de potencia que has realizado se utiliza para detectar diferencias entre medias, basándose en el tamaño del efecto observado.

3. **Fórmula para Comparación de Medias**
   - Para comparar medias, el tamaño muestral depende del tamaño del efecto (d de Cohen).
   - Con un efecto tan grande (d = 19,75), la fórmula da un resultado muy pequeño:
     n = 2 × (1,96 + 0,84)² / 19,75² ≈ 3

### E) Conclusiones: potencia estadística y representatividad.
- Los resultados de la encuesta son estadísticamente válidos y robustos y los tamaños muestrales son más que suficientes para la inferencia estadística sobre el gasto medio en alquiler por estudiante, nuestra principal variable de interés.
- Los resultados muestran una diferencia enorme y estadísticamente significativa en los gastos de alquiler entre los estudiantes de IE y UVA. 
- La magnitud de la diferencia es tan grande que explica por qué el tamaño muestral mínimo calculado es sorprendentemente pequeño.
