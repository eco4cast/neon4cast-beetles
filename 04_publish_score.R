
## publish() registers permanent content-based identifiers for the input data, code, and output data files.
## Data are made accessible through a public content-based storage on the server.
##  We can later resolve these identifiers to any registered source.  
## Core provenance information is stored 

source("publish.R")
base <- Sys.getenv("MINIO_HOME", ".")
provdb <-  file.path(base, "scores/prov.json")


richness_entries <- list.files(file.path(base, "forecasts"), "^beetle-richness.*\\.csv\\.gz$", full.names = TRUE)
richness_out <- paste0(file.path(base, "scores/beetle/"), gsub("forecast", "score", basename(richness_entries)))

## and here we go:
purrr::walk2(richness_entries, richness_out, 
             function(in_data, out_data) publish(in_data, "04_score.R", out_data, provdb = provdb)
)


abund_entries <- list.files(file.path(base, "forecasts"), "^beetle-abund.*\\.csv\\.gz$", full.names = TRUE)
abund_out <- paste0(file.path(base, "scores/beetle/"), gsub("forecast", "score", basename(abund_entries)))

purrr::walk2(abund_entries, abund_out, 
             function(in_data, out_data) publish(in_data, "04_score.R", out_data, provdb = provdb)
)

