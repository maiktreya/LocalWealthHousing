## Datos AEAT: Interpretación del fichero

Este directorio (data escrapers) contiene dos ficheros que acumulan en una sola matriz todas las observaciones diarias de los scrapers. Hay dos archivos .xlsx diferentes según el origen (AIRBNB & IDEALISTA).

### Estructura

Ambos ficheros comparten su estructura interna. Cada "mercado" analizado incluye dos ficheros:

* BASE: Fichero general con cada una de las propiedades extraidas cada día ocupando una fila independiente para almacenar su información.
* TOTALES: Contiene una tabla dinámica acumulando por días: 1) total de propiedades en oferrta. 2) precio medio de la propiedad 3) precio del metro cuadrado (solo para idealista.

### Contenido

* AIRBNB: corto, medio y largo plazo.
* IDEALISTA: mercado del alquiler y mercado de compraventa.
