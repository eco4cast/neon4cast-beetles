
library(fable)
library(distributional)
library(tidyverse)


## Get the latest beetle target data.  
download.file("https://data.ecoforecast.org/neon4cast-targets/beetles/beetles-targets.csv.gz",
              "beetles-targets.csv.gz")
targets <-  read_csv("beetles-targets.csv.gz")

curr_iso_week <- ISOweek::ISOweek(Sys.Date())

curr_date <- ISOweek::ISOweek2date(paste0(curr_iso_week, "-1"))

site_list <- unique(targets$site_id)

last_day_richness <- tibble(site_id = site_list,
                   time = rep(curr_date, length(site_list)),
                   variable = "richness",
                   observed = NA)

last_day_abundance <- tibble(site_id = site_list,
                            time = rep(curr_date, length(site_list)),
                            variable = "abundance",
                            observed = NA)


targets_richness <- targets |> 
  filter(variable == "richness") |> 
  bind_rows(last_day_richness) |> 
  rename(richness = observed) |> 
  select(-variable) |> 
  as_tsibble(index = time, key = site_id)

targets_abundance <- targets |> 
  filter(variable == "abundance") |> 
  bind_rows(last_day_abundance) |> 
  rename(abundance = observed) |> 
  select(-variable) |> 
  as_tsibble(index = time, key = site_id)

## a single mean per site... obviously silly
fc_richness <- targets_richness  %>% 
  model(null = MEAN(richness)) %>%
  forecast(h = "1 year")

fc_abundance <- targets_abundance  %>%
  model(null = MEAN(abundance)) %>%
  forecast(h = "1 year")


efi_statistic_format <- function(df){
  ## determine variable name
  var <- attributes(df)$dist
  ## Normal distribution: use distribution mean and variance
  df %>% 
    dplyr::mutate(sd = sqrt( distributional::variance( .data[[var]] ) ) ) %>%
    dplyr::rename(mean = .mean) %>%
    dplyr::select(time, site_id, .model, mean, sd) %>%
    tidyr::pivot_longer(c(mean, sd), names_to = "parameter", values_to = var) %>%
    pivot_longer(tidyselect::all_of(var), names_to="variable", values_to = "predicted") |> 
    mutate(family = "norm")
}

fc_richness |> 
  filter(site_id == "BARR") |> 
autoplot()

efi_richness <- efi_statistic_format(fc_richness)
efi_abundance <-  efi_statistic_format(fc_abundance)
forecast <- bind_rows(efi_richness, efi_abundance) |> 
  select(time, site_id, family, parameter, variable, predicted)

## Create the metadata record, see metadata.Rmd
theme_name <- "beetles"
time <- min(forecast$time)
team_name <- "mean"
filename <- paste0(theme_name, "-", time, "-", team_name, ".csv.gz")

## Store the forecast products
readr::write_csv(forecast, filename)

neon4cast::submit(forecast_file = filename, 
                  ask = FALSE)


