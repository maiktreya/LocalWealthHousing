/**********************************************************************************************************************				
Instituto Nacional de Estadística (INE) www.ine.es				
***********************************************************************************************************************				
				
DESCRIPCIÓN:				
Este programa genera un fichero SAS con formatos, partiendo de un fichero sin ellos.				
				
Consta de las siguientes partes:				
	* 1. Definir la librería de trabajo --> Libname			
	* 2. Definición de formatos --> PROC FORMAT			
	* 3. Vincular formatos a la base de datos --> PASO data			
				
 Entrada:                                                           				
     - Fichero SAS sin formatos: 	 ECHHogares_2017.sas7bdat			
 Salida:                                                           				
     - Fichero SAS con formatos: 	 ECHHogares_2017_conFormato.sas7bdat			
				
Donde:				
	* Operación: ECHHogares Encuesta Continua de Hogares			
	* Periodo: 2017			
				
************************************************************************************************************************/				
				
/*1) Definir la librería de trabajo: introducir el directorio que desee como librería				
(se da como ejemplo 'C:\Mis resultados'), y copiar en ese directorio el fichero sas "ECHHogares_2017.sas7bdat"*/				
				
libname ROutput 'C:\Mis resultados';				

options fmtsearch = (ROutput ROutput.cat1);

* 2) DEFINICIÓN DE FORMATOS;
PROC FORMAT LIBRARY=ROutput.cat1;
value $TCCAA

"01"="Andalucía"
"02"="Aragón"
"03"="Asturias, Principado de"
"04"="Balears, Illes"
"05"="Canarias"
"06"="Cantabria"
"07"="Castilla y León"
"08"="Castilla-La Mancha"
"09"="Cataluña"
"10"="Comunitat Valenciana"
"11"="Extremadura"
"12"="Galicia"
"13"="Madrid, Comunidad de"
"14"="Murcia, Región de"
"15"="Navarra, Comunidad Foral de"
"16"="País Vasco"
"17"="Rioja, La"
"18"="Ceuta"
"19"="Melilla"
;
value $TProv

"01"="Araba/Álava"
"02"="Albacete"
"03"="Alicante/Alacant"
"04"="Almería"
"05"="Ávila"
"06"="Badajoz"
"07"="Balears, Illes"
"08"="Barcelona"
"09"="Burgos"
"10"="Cáceres"
"11"="Cádiz"
"12"="Castellón /Castelló"
"13"="Ciudad Real"
"14"="Córdoba"
"15"="Coruña, A"
"16"="Cuenca"
"17"="Girona"
"18"="Granada"
"19"="Guadalajara"
"20"="Gipuzkoa"
"21"="Huelva"
"22"="Huesca"
"23"="Jaén"
"24"="León"
"25"="Lleida"
"26"="Rioja, La"
"27"="Lugo"
"28"="Madrid"
"29"="Málaga"
"30"="Murcia"
"31"="Navarra"
"32"="Ourense"
"33"="Asturias"
"34"="Palencia"
"35"="Palmas, Las"
"36"="Pontevedra"
"37"="Salamanca"
"38"="Santa Cruz de Tenerife"
"39"="Cantabria"
"40"="Segovia"
"41"="Sevilla"
"42"="Soria"
"43"="Tarragona"
"44"="Teruel"
"45"="Toledo"
"46"="Valencia/València"
"47"="Valladolid"
"48"="Bizkaia"
"49"="Zamora"
"50"="Zaragoza"
"51"="Ceuta"
"52"="Melilla"
;
value $TMuni

"1"="Menos de 101 habitantes"
"2"="101-500 habitantes"
"3"="501-1.000 habitantes"
"4"="1.001-2.000 habitantes"
"5"="2.001-5.000 habitantes"
"6"="5.001-10.000 habitantes"
"7"="10.001-20.000 habitantes"
"8"="20.001-50.000 habitantes"
"9"="50.001-100.000 habitantes"
"10"="100.001-500.000 habitantes"
"11"="500.001 o más habitantes"
;
value $TCocin

"1"="Si"
"6"="No"
" "="No procede responder"
;
value $TRegimV

"1"="Propia por compra, totalmente pagada, heredada o donada"
"2"="Propia por compra con hipotecas"
"3"="Alquilada"
"4"="Cedidas gratis o bajo precio por otro hogar, la empresa..."
" "="No procede responder"
;
value $TipoViv

"1"="Unifamiliar independiente"
"2"="Unifamiliar adosada o pareada"
"3"="Edificio con dos viviendas"
"4"="Edificio entre 3 y 9 viviendas"
"5"="Edificio con 10 o más viviendas"
"6"="Edificio destinado a otros usos (e incluye una o más viviendas convencionales)"
" "="No procede responder"
;
value $TAnoEd

"1"="Después del año 2000"
"2"="Entre 1991-2000"
"3"="Entre 1981-1990"
"4"="Entre 1971-1980"
"5"="Entre 1961-1970"
"6"="Entre 1951-1960"
"7"="Entre 1941-1950"
"8"="Entre 1921-1940"
"9"="Antes de 1921"
" "="No procede responder"
;
value $TFechEd

"01"="Antes de 1921"
"02"="Entre 1921 y 1940"
"03"="Entre 1941 y 1950"
"04"="Entre 1951 y 1960"
"05"="Entre 1961 y 1970"
"06"="Entre 1971 y 1980"
"07"="Entre 1981 y 1990"
"08"="Entre 1991 y 2000"
"09"="Entre 2001 y 2005"
"10"="Entre 2006 y 2010"
"11"="Posterior al 2010"
"  "="No aplicable"
;
value $TipoHog

"1"="Persona sola menor de 65 años"
"2"="Persona sola de 65 años o más"
"3"="Madre/padre solo con algún hijo menor de 25 años"
"4"="Madre/padre solo con algún hijo todos mayores de 24 años"
"5"="Pareja sin hijos que convivan en el hogar"
"6"="Pareja con hijos de ambos miembros que conviven en el hogar alguno menor de 25 años"
"7"="Pareja con hijos de ambos miembros que conviven en el hogar todos mayores de 24 años"
"8"="Pareja con algún hijo de un solo miembro y además alguno de los hijos menor de 25 años (4.2.1)"
"9"="Pareja con algún hijo de un solo miembro que conviven en el hogar todos mayores de 25 años (4.2.2)"
"10"="Pareja con algún hijo menor de 25 años y otras personas"
"11"="Madre/padre con algún hijo menor de 25 años y otras personas"
"12"="Pareja o Madre/padre con algún hijo todos mayores de 24 años y otras personas."
"13"="Pareja sin hijos y otros familiares"
"14"="Pareja sin hijos y otras personas alguna de ellas no tiene relación de parentesco con la pareja"
"15"="Personas que no forman pareja y si tienen parentesco es distinto de padre e hijo"
"16"="Otros (más de un núcleo)"
"  "="No aplicable"
;
value $TNacHg

"1"="Hogar nacional. Sólo con españoles"
"2"="Hogar nacional. Con españoles y extranjeros"
"3"="Hogar extranjero. Sólo con una nacionalidad"
"4"="Hogar extranjero. Con diversas nacionalidades"
" "="No aplicable"
;
value $TNucleF

"1"="Pareja casada con o sin hijos, con o sin otras personas"
"2"="Pareja de hecho con o sin hijos, con o sin otras personas"
"3"="Madre con hijos, con o sin otras personas"
"4"="Padre con hijos, con o sin otras personas"
" "="No aplicable"
;


* 3) VINCULAR FORMATOS A LA BASE DE DATOS;
data ROutput.ECHHogares_2017_ConFormato;
	set ROutput.ECHHogares_2017;



FORMAT TAMANO $TMuni.;
FORMAT IDQ_PV $TProv.;
FORMAT CA $TCCAA.;
FORMAT REGVI $TRegimV.;
FORMAT COCINA $TCocin.;
FORMAT TIPOVIV $TipoViv.;
FORMAT ANEDI $TAnoEd.;
FORMAT FEDI $TFechEd.;
FORMAT TIPOHO $TipoHog.;
FORMAT NACHO $TNacHg.;
FORMAT NUCLEOFAM $TNucleF.;


RUN;
/* FIN PROGRAMA: Microdatos en SAS: ECHHogares_2017.sas*/
