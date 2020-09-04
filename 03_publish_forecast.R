
## publish() registers permanent content-based identifiers for the input data, code, and output data files.
## Data are made accessible through a public content-based storage on the server.
##  We can later resolve these identifiers to any registered source.  
## Core provenance information is stored 

source("R/publish.R")
base <- Sys.getenv("MINIO_HOME", ".")
provdb <-  file.path(base, "forecasts/prov.json")


in_richness <- file.path(base, "targets/beetle/richness.csv.gz")
code <- "03_forecast.R"
out_richness <- file.path(base, "forecasts/beetle-richness-forecast-team_null_average.csv.gz")

## Publish the richness input, code, and output, log this to prov log
publish(in_richness, code, out_richness, provdb = provdb)


in_abund <- file.path(base, "targets/beetle/abund.csv.gz")
code <- "03_forecast.R"
out_abund <- file.path(base, "forecasts/beetle-abund-forecast-team_null_average.csv.gz")

## Publish the abnd input, code, and output, and also log this to prov log
publish(in_abund, code, out_abund, provdb = provdb)


## The prov log now contains a record (in JSON-LD serialization of DCAT2 RDF)
## of the precise inputs and outputs used.  
## These objects can be retrieved from the server by using `contentid::resolve(id)`
