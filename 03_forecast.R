library(tidyverse)
base <- Sys.getenv("MINIO_HOME", ".")

## For illustrative purposes, restrict forecast to 2019
forecast_year <- 2019

## Read in the target data.  
## NOTE: in general a forecast may instead be made directly from the 
## the raw data, and may include other drivers.  Using only the target
## variables for prediction is merely a minimal model.  


richness <- read_csv(file.path(base, "targets/beetle/richness.csv.gz"))
abund <- read_csv(file.path(base, "targets/beetle/abund.csv.gz"))

## Forecast is just based on historic mean/sd by siteID & month
richness_model <- richness %>% 
  filter(year < forecast_year) %>%
  group_by(month, siteID) %>%
  summarize(mean = mean(n, na.rm = TRUE),
            sd = sd(n, na.rm = TRUE)) %>% 
  mutate(sd = replace_na(sd, mean(sd, na.rm=TRUE))) %>% 
  mutate(year = forecast_year)


abund_model <- abund %>% 
  filter(year < forecast_year) %>%
  group_by(month, siteID) %>%
  summarize(mean = mean(abund, na.rm=TRUE),
            sd = sd(abund, na.rm=TRUE))  %>% 
  mutate(sd = replace_na(sd, mean(sd, na.rm=TRUE))) %>% 
  mutate(year = forecast_year)

### Express forecasts in terms of replicates instead of analytic mean, sd.
### This allows for scoring using CRPS, and generalizes to MCMC-based forecasts

mcmc_samples <- function(df, n_reps = 500){
  ids <- df %>%
    mutate(id = paste(siteID, year, month, sep="-")) %>% 
    pull(id)
  map_dfr(seq_along(ids), 
          function(i) data.frame(id = ids[i],
                                 rep = 1:n_reps, 
                                 y = rnorm(n_reps, df$mean[[i]], df$sd[[i]])))
}

n_reps = 500
richness_forecast <- mcmc_samples(richness_model, n_reps)
abund_forecast <- mcmc_samples(abund_model, n_reps)


## Store the forecast products
readr::write_csv(richness_forecast, file.path(base, "forecasts/beetle/richness_forecast.csv.gz"))
readr::write_csv(abund_forecast,  file.path(base, "forecasts/beetle/abund_forecast.csv.gz"))




