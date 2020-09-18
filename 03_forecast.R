
renv::restore()

library(tidyverse)

## Read in the target data.  
## NOTE: in general a forecast may instead be made directly from the 
## the raw data, and may include other drivers.  Using only the target
## variables for prediction is merely a minimal model.  
null_forecast <- function(targets, forecast_year = 2019){
  ## Forecast is just based on historic mean/sd by siteID & month
  model <- targets %>% 
    filter(year < forecast_year) %>%
    group_by(month, siteID, target) %>%
    summarize(mean = mean(value, na.rm = TRUE),
              sd = sd(value, na.rm = TRUE)) %>% 
    mutate(sd = replace_na(sd, mean(sd, na.rm=TRUE))) %>% 
    mutate(year = forecast_year)
  
  ### Express forecasts in terms of replicates instead of analytic mean, sd.
  ### This allows for scoring using CRPS, and generalizes to MCMC-based forecasts
  
  mcmc_samples <- function(df, n_reps = 500){
    
    map_dfr(1:nrow(df), 
            function(i) data.frame(siteID = df$siteID[[i]],
                                   year = df$year[[i]],
                                   month = df$month[[i]],
                                   target = df$target[[i]],
                                   rep = 1:n_reps, 
                                   value = rnorm(n_reps, df$mean[[i]], df$sd[[i]])))
  }
  
  n_reps <- 500
  forecast <- mcmc_samples(model, n_reps)
}


## Get the latest beetle target data.  
download.file("https://data.ecoforecast.org/targets/beetle/beetle-targets.csv.gz",
              "beetle-targets.csv.gz")
targets <-  read_csv("beetle-targets.csv.gz")

## Make the forecast
forecast <- null_forecast(targets)

## Store the forecast products
readr::write_csv(forecast, "beetle-forecast-null_average.csv.gz")

## Create the metadata record, see metadata.Rmd


## Publish the forecast automatically. (EFI-only)
source("R/publish.R")
publish(code = "03_forecast.R",
        data_in = "beetle-targets.csv.gz",
        data_out = "beetle-forecast-null_average.csv.gz",
        meta = "meta/eml.xml",
        prefix = "beetle/",
        bucket = "forecasts")



