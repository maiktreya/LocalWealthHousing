# Guía de Utilización

Esta página describe las distintas funcionalidades implementadas en este proyecto para explotar las muestras de declarantes de IRPF/patrimonio publicadas por la AEAT, incluyendo su extracción, transformación vectorial y análisis estadístico de algunas variables de interés.

**NOTA:** Es necesario solicitar a la AEAT los ficheros base con los que trabaja este proyecto. Puedes solicitarlos desde [aquí](https://www.agenciatributaria.es/).

## 1. Extracción de variables y optimización matricial

Para extraer las distintas variables de interés, es necesario trabajar con los ficheros base proporcionados por la AEAT. El script `AEAT/src/transform/IEF_get-mainfiles.R` permite realizar esta operación automáticamente para los ejercicios 2016 y 2021. El resultado es un fichero optimizado que unifica las variables de interés para el año de referencia.

## 2. Transformación de la muestra para explotación estadística

Por defecto, el objeto `.gz` obtenido en el paso anterior permite su explotación con distintas poblaciones como referencia general. El script `AEAT/src/transform/etl_pipe.R` contiene la función `get_wave`, que es utilizada por otros scripts para establecer tanto la población objetivo como el ejercicio de análisis.

- La variable `sel_year` refleja el año a analizar.
- La variable `represet` permite elegir el universo de referencia, con opciones como la población total o los declarantes como unidad de referencia.
- La variable `ref_unit` fija el nivel base de identificación (a elegir entre personas y hogares).

## 3. Explotación estadística

El script principal, `AEAT/src/pop-stats-informe2023.R`, permite realizar un análisis estadístico robusto de las variables de interés (centrado en la obtención de rentas inmobiliarias), utilizando el paquete `survey` para considerar los pesos muestrales.

Este script también exporta los resultados principales en tablas `.CSV` en la carpeta `AEAT/out`.

El archivo alternativo, con extensión `-old`, utiliza una metodología diferente sin unificar los tipos de hogar en la categoría `tenencia` (utilizada en el informe de alquiler 2023), obteniendo los mismos resultados que el archivo principal.

## 4. Submuestreo y representatividad para estratos inferiores (municipios)

Este proyecto permite la explotación de submuestras, dado el gran tamaño de la muestra base (aproximadamente 5% del censo).

El principal objetivo de esta funcionalidad es permitir el análisis de patrimonio y extracción de rentas a nivel municipal, una escala que escapa a las capacidades de encuestas convencionales sobre renta y patrimonio (como la ECV o EFF), debido al tamaño limitado de sus muestras.

Aunque la inferencia de valores poblacionales reales para un municipio suele ser robusta, no está garantizada ex ante. El script `AEAT/src/tests/representativity.R` permite analizar la representatividad de submuestras de un municipio en particular, siempre que se dispongan de los valores poblacionales correspondientes.

En caso de problemas de representatividad, el script `AEAT/src/tests/representativity-raking.R` puede corregir los sesgos recalibrando los pesos de la submuestra. Es necesario proporcionar frecuencias y distribuciones marginales de las variables demográficas utilizadas para la recalibración. Por defecto, esta versión utiliza sexo y grupo de edad (valores disponibles solo para Madrid capital).

**Importante:** La muestra garantiza representatividad a nivel nacional y de las Comunidades Autónomas. Para análisis a nivel provincial o municipal, se recomienda verificar la representatividad de la submuestra antes de realizar inferencias estadísticas.

Para conocer las funcionalidades para recalibrar pesos y analizar su representatividad [Guía de calibrado y representatividad](md/reweighting.md)