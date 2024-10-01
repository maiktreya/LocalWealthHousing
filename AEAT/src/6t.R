

dt <- fread("AEAT/data/segovia-sex.csv")
dt[,freqmale := male /total]
dt[,freqfemale := female /total]

dt <- dt[age_group == "total", total2021]

dt[, freq2016 := total2016 / total16][, freq2021 := total2021 / total21 ]

dt <- dt[,.(age_group, freq2016, freq2021)]

fwrite( t(dt), "AEAT/data/segovia-sex-freq.csv" )

dt <- dt[,.(year, freqmale, freqfemale)]