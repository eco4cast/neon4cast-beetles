library(neonstore)

## full API queries take ~ 2m.  
## full download takes ~ 5m (on Jetstream)
# Set start_date to only fetch more recent-than files.  
neonstore::neon_download(product="DP1.10022.001")

## Optionally, publish the file index. Not needed since we will archive the local store!
# source("R/publish.R")
# raw_file_index <- neon_index(product="DP1.10022.001", hash = "md5")
# readr::write_csv(raw_file_index, "products/raw_file_index.csv")
# publish("products/raw_file_index.csv")

