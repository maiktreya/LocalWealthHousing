# **Análisis del costo del alquiler en estudiantes de IE y UVA**

## **1. Descripción del estudio**
Este análisis evalúa la diferencia en el costo del alquiler mensual entre estudiantes de la Universidad IE y la Universidad de Valladolid (UVA). Se utilizan datos recopilados de encuestas en ambas universidades, aplicando técnicas de muestreo ponderado para garantizar representatividad.

## **2. Datos y muestreo**

### **2.1 Población y muestra**
- **Población total:**
  - IE University: 3.923 estudiantes
  - UVA (campus Valladolid): 2.323 estudiantes
- **Muestras analizadas:**
  - IE University: 51 estudiantes (≈ 1,3% de la población)
  - UVA: 61 estudiantes (≈ 2,6% de la población)

### **2.2 Pesos muestrales**
Para corregir la diferencia en tasas de muestreo entre ambas universidades, se asignan pesos de muestreo como:

\[ w = \frac{N}{n} \]

Donde:
- \(N\) es la población total de la universidad correspondiente.
- \(n\) es el tamaño muestral de la universidad correspondiente.

Estos pesos se utilizan en los cálculos de estimación de medias y pruebas estadísticas.

## **3. Metodología estadística**

### **3.1 Estimación del gasto medio en alquiler**
Se calcula la media ponderada del costo mensual del alquiler en cada universidad utilizando la función `svymean()` de la librería `survey`. Además, se estiman los intervalos de confianza al 95%.

**Manejo de valores faltantes:**
- Se excluyen valores NA (`na.rm = TRUE`) en el cálculo de las medias.
- No se realizó una imputación múltiple explícita en este análisis.

### **3.2 Prueba de hipótesis: Comparación de medias**
Se evalúa si la diferencia en el costo del alquiler entre ambas universidades es estadísticamente significativa mediante una prueba *t* para muestras independientes, utilizando los pesos muestrales.

Hipótesis:
- \(H_0\): No hay diferencia en el gasto promedio de alquiler entre estudiantes de IE y UVA.
- \(H_A\): El gasto promedio en alquiler es significativamente diferente entre ambas universidades.

### **3.3 Cálculo del tamaño del efecto (Cohen's d)**
Para evaluar la magnitud de la diferencia, se calcula el tamaño del efecto de Cohen:

\[ d = \frac{M_{IE} - M_{UVA}}{SD_{pooled}} \]

Donde \(SD_{pooled}\) es la desviación estándar agrupada de ambas muestras. Se utiliza `SE(ie_mean)` y `SE(uv_mean)` para calcular este valor.

**Nota importante:** Se observó un valor muy alto de \(d = 19,75\), lo que indica una diferencia extraordinaria en el costo del alquiler. Sin embargo, valores tan altos pueden deberse a una escala de precios muy diferente entre ambas universidades o a una desviación estándar extremadamente pequeña. Se recomienda interpretar con precaución.

### **3.4 Cálculo del tamaño muestral mínimo**
Se determina el tamaño muestral requerido para detectar un efecto con una potencia del 80% mediante `pwr.t.test()`, con un tamaño del efecto basado en \(d = min(19,75, 5)\), limitando a 5 para evitar distorsiones extremas. El resultado indica que **incluso con muestras pequeñas (≈3 estudiantes por grupo), la diferencia sería estadísticamente detectable**.

## **4. Consideraciones sobre la validez del estudio**
- **Representatividad:**
  - Aunque las muestras representan un pequeño porcentaje de cada universidad, los pesos muestrales garantizan una mejor aproximación a la población real.
  - Sin embargo, la posibilidad de **sesgo de autoselección** no puede descartarse. No se evaluó si las características de los participantes encuestados son homogéneas respecto a la población universitaria total.
- **Interpretación de resultados:**
  - Dado el valor inusualmente alto de \(d\), podría haber factores adicionales que influyen en la gran diferencia observada.
  - Se recomienda realizar un análisis adicional con datos de renta promedio en cada área geográfica para contextualizar los hallazgos.

## **5. Conclusión**
Los resultados muestran una diferencia muy significativa en el costo del alquiler entre estudiantes de IE y UVA, con valores que sugieren una gran disparidad. Sin embargo, debido a la magnitud del efecto, se recomienda cautela en la interpretación y considerar factores adicionales en estudios futuros.

