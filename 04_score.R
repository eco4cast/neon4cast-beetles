renv::restore()
## 04_score.R
library(tidyverse)
library(scoringRules)

efi_score <- function(forecasts, targets){
  crps_score <- function(forecast,
                         target){
    
    ## Teach crps to treat NA observations as NA scores:
    scoring_fn <- function(y, dat) 
      tryCatch(scoringRules::crps_sample(y, dat), error = function(e) NA_real_, finally = NA_real_)
    
    ## Left-join will keep only the rows for which site,month,year of the target match the predicted
    left_join(forecast, 
              rename(target, true = value),
              by = c("siteID", "month", "year", "target"))  %>% 
      mutate(id = paste(siteID, year, month, target, sep="-")) %>%
      group_by(id) %>% 
      summarise(score = scoring_fn(true[[1]], value))
  }
  
  scores <- lapply(forecasts, crps_score, targets)

}



## Get the latest beetle target data.  
Sys.setenv("AWS_DEFAULT_REGION" = "data",
           "AWS_S3_ENDPOINT" = "ecoforecast.org")
targets_file <- aws.s3::save_object("beetle/beetle-targets.csv.gz", 
                                    bucket = "targets")


## Get all beetle forecasts
index <- aws.s3::get_bucket("forecasts")
keys <- vapply(index, `[[`, "", "Key", USE.NAMES = FALSE)
keys <- keys[grepl("beetle-forecast", keys)]
lapply(keys, aws.s3::save_object, bucket = "forecasts")
forecast_files <- basename(keys)

## Read in data and compute scores!
targets <- read_csv(targets_file)
forecasts <- lapply(forecast_files, read_csv)
scores <- efi_score(forecasts, targets)

## write out score files
score_files <- gsub("forecast", "score", forecast_files)
purrr::walk2(scores, score_files, readr::write_csv)


## Publish
source("R/publish.R")
publish(code = "04_score.R",
        data_in = c(targets_file, forecast_files),
        data_out = score_files,
        prefix = "beetle/",
        bucket = "scores")


