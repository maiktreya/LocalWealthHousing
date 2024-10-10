# 🛠️ AEAT muestra cruzada IRPF & PATRIMONIO

Este proyecto utiliza la muestra anual de información fiscal en España. La muestra se obtiene cruzando delcaraciones de IRPF con información del impuesto de patrimonio, registro catastral y del censo general (INE). Es elaborada por la Agencia Tributaria (AEAT) proporcionando datos desde 2016.

Para conocer como usar este proyecto utiliza nuestra [Guía de Utilización](md/tutorial.md)

---

## 🚀 Explotando las ventajas del big-data fiscal

La muestra se caracteriza por su gran tamaño de aproximadamente el 5% del censo total, con información procendete de casi 3 millones de habitantes y más de 1 millon de hogares.

Este gran tamaño permite que, aunque el diseño original considere representatividad a escala de las CCAA, poder realizar inferencia para unidades de inferior tamaño hasta un limite sobre los 5000 habitantes por CCAA para obtener resultados robustos.

Para ver los resultados de un caso práctico de recalibración efectivo echa un vistazo a este ejemplo [Estimando nuevos pesos muestrales iterativamente para Madrid capital](md/reweighting/results-calib.es.md)

---

## 🎯 Objetivo: riqueza y propiedad en blos municipios de España

En pocas palabras, este proyecto busca facilitar una metodología para realizar inferencia estadística robusta a nivel municipal mostrando el estudio de caso de segovia como ejemplo práctico.

La posibilidad de trabajar con esta muestra bajando a la escala más micro hasta el nivel municipal es pionera en los estudios de patrimonio, renta y desigualdad de los hogares.

Hasta la publicación de este tipo de muestras, la información obtenida a través de encuestas convencionales estaba limitada de manera muy importante por su coste de recolección, limitando en gran medida el tamaño de la muestra, que pocas veces supera en el caso de España los 15000 encuestados en total para estudios de riqueza, haciendo imposible hacer inferencia a cualquier escala inferior a la autonómica.

---

## 🔒 Licencia

Este proyecto está licenciado bajo la Licencia Pública General de GNU (GPL-3). Consulta la licencia completa [aquí](https://www.gnu.org/licenses/gpl-3.0.en.html).

---
