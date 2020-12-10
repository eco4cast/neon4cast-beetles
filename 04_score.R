# renv::restore()
## 04_score.R
library(tidyverse)
library(scoringRules)


## Generic scoring function.
crps_score <- function(forecast, target,
                       grouping_variables = c("siteID", "time"),
                       target_variables = c("richness", "abundance"),
                       reps_col = "ensemble"){
  
  ## drop extraneous columns && make grouping vars into chr ids (i.e. not dates)
  variables <- c(grouping_variables, target_variables, reps_col)
  
  forecast <- forecast %>% select(any_of(variables))
  target <- target %>% select(any_of(variables)) 
  
  ## Teach crps to treat any NA observations as NA scores:
  scoring_fn <- function(y, dat) {
    tryCatch(scoringRules::crps_sample(y, dat), error = function(e) NA_real_, finally = NA_real_)
  }
  
  ## Make tables into long format
  target_long <- target %>% 
    pivot_longer(any_of(target_variables), 
                 names_to = "target", 
                 values_to = "observed") %>%
    tidyr::unite("id", -all_of("observed"))
  
  forecast_long <- forecast %>% 
    pivot_longer(any_of(target_variables), 
                 names_to = "target", 
                 values_to = "predicted") %>%
    unite("id", -all_of(c(reps_col, "predicted")))
  
  
  ## Left-join will keep only the rows for which site,month,year of the target match the predicted
  inner_join(forecast_long, target_long, by = c("id"))  %>% 
    group_by(id) %>% 
    summarise(score = scoring_fn(observed[[1]], predicted),
              .groups = "drop")
  
}

## apply over a full collection (list) of forecasts
efi_score <- function(forecasts, target, ...){
  scores <- lapply(forecasts, crps_score, target,  ...)

}

## here we go:

## Get the latest beetle target data.  
Sys.setenv("AWS_DEFAULT_REGION" = "data",
           "AWS_S3_ENDPOINT" = "ecoforecast.org")
targets_file <- aws.s3::save_object("beetles/beetles-targets.csv.gz", 
                                    bucket = "targets")


## Get all beetle forecasts
index <- aws.s3::get_bucket("forecasts")
keys <- vapply(index, `[[`, "", "Key", USE.NAMES = FALSE)
keys <- keys[grepl("beetles.*[.]csv", keys)]
lapply(keys, aws.s3::save_object, bucket = "forecasts")
forecast_files <- basename(keys)

## Read in data and compute scores!
target <- read_csv(targets_file)
forecasts <- lapply(forecast_files, read_csv)


scores <- efi_score(forecasts, target)

## write out score files
score_files <- gsub("forecast", "score", forecast_files)
purrr::walk2(scores, score_files, readr::write_csv)


## Publish
source("R/publish.R")
publish(code = "04_score.R",
        data_in = c(targets_file, forecast_files),
        data_out = score_files,
        prefix = "beetles/",
        bucket = "scores")


