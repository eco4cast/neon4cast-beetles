library(tidyverse)
library(fable)
library(distributional)



## Helper functions to turn a fable timeseries, which uses a special "distribution" column,
## into a flat-file format.  efi_statistic_format uses a 'statistic' column (indicating either mean or sd),
## while efi_ensemble_format uses an 'ensemble' column, drawing `n` times from the distribution. 
# Confirm these are correct if the variable is transformed first!
efi_statistic_format <- function(df){
  ## determine variable name
  var <- attributes(df)$dist
  ## Normal distribution: use distribution mean and variance
  df %>% 
    dplyr::mutate(sd = sqrt( distributional::variance( .data[[var]] ) ) ) %>%
    dplyr::rename(mean = .mean) %>%
    dplyr::select(time, siteID, .model, mean, sd) %>%
    tidyr::pivot_longer(c(mean, sd), names_to = "statistic", values_to = var)
}


efi_ensemble_format <- function(df, times = 10) {
  ## determine variable name
  var <- attributes(df)$dist
  n_groups <- nrow(df)
  ## Draw `times` samples from distribution using 
  suppressWarnings({
    expand <- df %>% 
      dplyr::mutate(sample = distributional::generate.distribution(  .data[[var]], times) )
  })
  expand %>%
    tidyr::unnest(sample) %>%
    dplyr::mutate(ensemble = rep(1:times, n_groups)) %>%
    dplyr::select(time, siteID, ensemble, {{var}} := sample)
}


library(tidyverse)
library(fable)
library(distributional)

## Get the latest beetle target data.  
targets <-  read_csv("https://data.ecoforecast.org/targets/beetles/beetles-targets.csv.gz")
## Coerce to a "tsibble" time-series-data-table
targets <- as_tsibble(targets, index = time, key = siteID)

## Compute a simple mean/sd model per site... obviously silly given huge seasonal aspect
fc_richness <- targets  %>% 
  model(null = MEAN(richness)) %>%
  forecast(h = "1 year")

fc_abundance <- targets  %>%
  model(null = MEAN(abundance)) %>%
  forecast(h = "1 year")

## Combine richness and abundance forecasts. drop the 'model' column since we have only one model here
forecast <- inner_join( efi_format(fc_richness), efi_format(fc_abundance) ) %>% select(!.model)

## Write out the forecast file
filename <- glue::glue("beetles-{date}-{team}.csv.gz", date=Sys.Date(), team = "EFI_null")
readr::write_csv(forecast, filename)



## Create the metadata record, see metadata.Rmd



## STOP! This last command is for EFI use only!  
## This bit publishes the null forecast automatically.  For general submissions, see
## the `submit` function in https://github.com/eco4cast/neon4cast instead.
source("../challenge-ci/R/publish.R")
publish(code = "03_forecast.R",
        data_in = "beetles-targets.csv.gz",
        data_out = "beetles-2020-EFI_avg_null.csv.gz",
        meta = "meta/eml.xml",
        prefix = "beetles/",
        bucket = "neon4cast-forecasts")



