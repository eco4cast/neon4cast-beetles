
renv::restore()

library(tidyverse)

## Read in the target data.  
## NOTE: in general a forecast may instead be made directly from the 
## the raw data, and may include other drivers.  Using only the target
## variables for prediction is merely a minimal model.  
null_forecast <- function(targets, forecast_year = 2019){
  ## Forecast is just based on historic mean/sd by siteID & week
  model <- targets %>% 
    mutate(week = lubridate::isoweek(time),
           year = lubridate::isoyear(time))
    filter(year < forecast_year) %>%
    group_by(week, siteID) %>%
    summarize(mean_richness = mean(richness, na.rm = TRUE),
              sd_richness = sd(richness, na.rm = TRUE),
              mean_abundance = mean(abundance, na.rm = TRUE),
              sd_abundance = sd(abundance, na.rm = TRUE)
              ) %>% 
    mutate(sd_richness = replace_na(sd_richness, mean(sd_richness, na.rm=TRUE)),
           sd_abundance = replace_na(sd_abundance, mean(sd_abundance, na.rm=TRUE)),
          ) %>% 
    mutate(year = forecast_year)
  
  ### Express forecasts in terms of replicates instead of analytic mean, sd.
  ### This allows for scoring using CRPS, and generalizes to MCMC-based forecasts
  
  mcmc_samples <- function(df, n_reps = 500){
    map_dfr(1:nrow(df), 
            function(i) 
              data.frame(siteID = df$siteID[[i]],
                         time = paste0(df$year[[i]], "-W", df$week[[i]], "-1"),
                         ensemble = 1:n_reps, 
                         richness = rnorm(n_reps, 
                                          df$mean_richness[[i]], 
                                          df$sd_richness[[i]]),
                         abundance = rnorm(n_reps,
                                           df$mean_abundance[[i]],
                                           df$sd_abundance[[i]])
                         
                        )
            )
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
readr::write_csv(forecast, "beetles-2019-EFI_avg_null.csv.gz")

## Create the metadata record, see metadata.Rmd


## Publish the forecast automatically. (EFI-only)
source("R/publish.R")
publish(code = "03_forecast.R",
        data_in = "beetle-targets.csv.gz",
        data_out = "beetles-2019-EFI_avg_null.csv.gz",
        meta = "meta/eml.xml",
        prefix = "beetle/",
        bucket = "forecasts")



