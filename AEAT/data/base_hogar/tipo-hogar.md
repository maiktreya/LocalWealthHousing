# 10 estratos de panel de hogares AEAT para clasificar los hogares por tipo

1.1.1 Hogar unipersonal -65
1.1.2 Hogar unipersonal +65
1.1.3 Hogar con un solo +18
2.1.1 2+ Adultos y 1 menor
2.1.2 2+ Adultos y 2 menor
2.1.3 2+ Adultos y 3+ menor
2.2.1 2adultos (sin menores y alguno +65)
2.2.1 3+ adultos (sin menores y alguno +65)
2.3.1 2 adultos
2.3.2 3+ adultos


```r
# results from CENSO 2021 categories
 unique(dt$STRUCTURE)
 [1] "Hogar con una mujer sola menor de 65 años"                                                    
 [2] "Hogar con un hombre solo menor de 65 años"                                                    
 [3] "Hogar con una mujer sola de 65 años o más"                                                    
 [4] "Hogar con un hombre solo de 65 años o más"                                                    
 [5] "Hogar con un solo progenitor que convive con algún hijo menor de 25 años"                     
 [6] "Hogar con un solo progenitor que convive con todos sus hijos de 25 años o más"                
 [7] "Hogar formado por pareja sin hijos"                                                           
 [8] "Otro tipo de hogar"                                                                           
 [9] "Hogar formado por pareja con hijos en donde algún hijo es menor de 25 años"                   
[10] "Hogar formado por pareja con hijos en donde todos los hijos de 25 años o más"                 
[11] "Hogar formado por pareja o un solo progenitor que convive con algún hijo menor de 25 años y otra(s) persona(a)"

unique(dt$TYPE)
[1] "Hogar unipersonal"
[2] "Hogar de una familia sin otras personas adicionales y sólo un núcleo"
[3] "Hogar multipersonal pero que no forma familia"
[4] "Hogar de una familia sin otras personas adicionales y ningún núcleo"
[5] "Hogar de una familia sin otras personas adicionales y un núcleo y otras personas"
[6] "Hogar de una familia, con otras personas no emparentadas"
[7] "Hogar de una familia sin otras personas adicionales y dos núcleos o más"
[8] "Hogar de dos o más familias"
```