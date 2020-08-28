# NEON-community-forecast

- `00_configure.R` Configure the working directories where raw and output data will be stored. (optional)
- `01_download.R`  Download latest NEON data products, storing the raw data in `<NEONSTORE_HOME>`.  
- `02_targets.R`   Generate the target prediction variables from the raw data files. `<MINIO_HOME>/targets/beetle`.
- `03_forecast.R`  Run a dummy forecast and write out to csv files in `<MINIO_HOME>/forecasts/beetle`.
- `04_score.R`     Score the forecast and write out to csv files in `<MINIO_HOME>/scores/beetle`.

Ouptut data structure

`targets/beetle`, `forecasts/beetle`, and `scores/beetle`