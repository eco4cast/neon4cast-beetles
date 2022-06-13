
library(fable)
library(distributional)
library(tidyverse)
## Get the latest beetle target data.  
download.file("https://data.ecoforecast.org/targets/beetles/beetles-targets.csv.gz",
              "beetles-targets.csv.gz")
targets <-  read_csv("beetles-targets.csv.gz")
targets <- as_tsibble(targets, index = time, key = siteID)

## a single mean per site... obviously silly
fc_richness <- targets  %>% 
  model(null = MEAN(richness)) %>%
  forecast(h = "1 year")

fc_abundance <- targets  %>%
  model(null = MEAN(abundance)) %>%
  forecast(h = "1 year")


## Format a fable timeseries, fbl_ts, into EFI summary format
efi_statistic_format <- function(df){
  ## determine variable name
  var <- attributes(df)$dist
  ## Normal distribution: use distribution mean and variance
  df %>% 
    mutate(sd = sqrt( variance( .data[[var]] ) ) ) %>%
    rename(mean = .mean) %>%
    select(time, siteID, .model, mean, sd) %>%
    pivot_longer(c(mean, sd), names_to = "statistic", values_to = var)
}



efi_ensemble_format <- function(df, ensemble_members = 10) {
  ## determine variable name
  var <- attributes(df)$dist
  n_groups <- nrow(df)
  ## Normal distribution: use distribution mean and variance
  suppressWarnings({
  expand <- df %>% mutate(sample = generate(  .data[[var]], ensemble_members) )
  })
  expand %>%
    unnest(sample) %>% mutate(ensemble = rep(1:ensemble_members, n_groups)) %>%
    select(time, siteID, ensemble, {{var}} := sample)

}


inner_join( efi_format(fc_richness), efi_format(fc_abundance) )

  mutate(sd = variance(abundance)) %>%
  as_tibble() %>%
  select(time, siteID, mean = .mean, sd) %>%
  pivot_longer(c(mean, sd), names_to = "statistic", values_to = "abundance")

fc <- inner_join(fc_richness, fc_abundance)
# renv::restore()

library(tidyverse)
library(ISOweek) 
## NOTE: Forecast time refers to the ISOweek in which collection occurs, 
## not the precise day it occurs. (you don't want to predict the precise day).
## Thus a trap collection on 2016-01-01 occurs during ISO-week 2015-W53-1, 
## a.k.a. the week which began on Monday, 2015-12-28.
## In data files, all dates are given in standard ISO YYYY-MM-DD format, not
## in ISO week format.  

## NOTE: this creates forecasts only for those ISO-weeks which were observed in the sample data...

## Read in the target data.  
## NOTE: in general a forecast may instead be made directly from the 
## the raw data, and may include other drivers.  Using only the target
## variables for prediction is merely a minimal model.  
null_forecast <- function(targets, forecast_year = 2020){
  ## Forecast is just based on historic mean/sd by siteID & week
  model <- targets %>% 
    mutate(iso_week = ISOweek::date2ISOweek(time)) %>%
    separate(iso_week, into = c("year", "week", "day")) %>%
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
                         time = ISOweek::ISOweek2date(paste(df$year[[i]], 
                                                            df$week[[i]], 
                                                            "1", sep = "-")),
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
download.file("https://data.ecoforecast.org/targets/beetles/beetles-targets.csv.gz",
              "beetles-targets.csv.gz")
targets <-  readr::read_csv("beetles-targets.csv.gz")

## Make the forecast
forecast <- null_forecast(targets)


## Create the metadata record, see metadata.Rmd
theme_name <- "beetles"
time <- as.character(min(forecast$time))
team_name <- "EFInull"
filename <- paste0(theme_name, "-", time, "-", team_name, ".csv.gz")

## Store the forecast products
readr::write_csv(forecast, filename)

neon4cast::submit(forecast_file = filename, 
                  metadata = "meta/eml.xml", 
                  ask = FALSE)


