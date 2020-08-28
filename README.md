# NEON-community-forecast

- `00_configure.R` Configure the working directories where raw and output data will be stored. (optional)
- `01_download.R`  Download latest NEON data products, storing the raw data in `<NEONSTORE_HOME>`.  
- `02_targets.R`   Generate the target prediction variables from the raw data files. `<MINIO_HOME>/targets/beetle`.
- `03_forecast.R`  Run a dummy forecast and write out to csv files in `<MINIO_HOME>/forecasts/`.
- `04_score.R`     Score the forecast and write out to csv files in `<MINIO_HOME>/scores/beetle`.


## Workflow notes

- Running `01_download.R` and `02_targets.R` wil upldate the resulting  latest target data files can be found in `targets/beetle` directory.  Some time after challenge entries are submitted, this workflow will thus result in an updated set of targets that contains the true values for the sites and times that the teams were trying to submit.  

- The `04_score.R` script will score all `.csv.gz` forecasts found in the `forecasts/` directory that start with `beetle-richness-forecast-<project_id>.csv.gz` or `beetle-abund-forecast-<project_id>.csv.gz` respectively (and conform to the same tabular structure used here: columns of: siteID, month, year, value, rep).  These scores will be written out to `scores/beetle` using filenames that correspond to the submission files, replacing `forecast` with `score`.   

- `03_forecast.R` generates a benchmark forecast based on a simple null model (historical mean and standard deviation).  Entry teams will replace this script with their own more involved forecasting mechanisms, generating output forecasts that follow the above filenaming convention.  These can be uploaded directly to the challenge server at URL TBD.  

- The Challenge Coordinating Team server will use a `cron` job to regularly (intervals TBD) run the full workflow scripts, resulting in updated raw data, derived data, benchmark forecast, and scores for any submissions.

## Access / Publishing of target, null forecast, and scores

All files are exposed via public buckets on MINIO for now. Automated functions need to be added that will publish the target, benchmark forecast, and possibly benchmark scores in a persistent, version-controlled manner.  details TBD


