# rscript resampling segovia
library("magrittr")
library("data.table")
library("survey")
rm(list = ls()) # clean enviroment to avoid ram bottlenecks

dt <- fread("AEAT/data/IEF-2021-new.gz")

print(colnames(dt))

segovia <- dt[CCAA == "7" & PROV == "40" & MUNI == "194"]
san_cristobal <- dt[CCAA == "7" & PROV == "40" & MUNI == "906"]
palazuelos <- dt[CCAA == "7" & PROV == "40" & MUNI == "155"]
la_lastrilla <- dt[CCAA == "7" & PROV == "40" & MUNI == "112"]
villaverde <- dt[CCAA == "7" & PROV == "40" & MUNI == "130"]

print(nrow(segovia))
print(nrow(san_cristobal))
print(nrow(palazuelos))
print(nrow(la_lastrilla))
print(nrow(villaverde))
