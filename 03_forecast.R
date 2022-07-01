
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


efi_statistic_format <- function(df){
  ## determine variable name
  var <- attributes(df)$dist
  ## Normal distribution: use distribution mean and variance
  df %>% 
    dplyr::mutate(sd = sqrt( distributional::variance( .data[[var]] ) ) ) %>%
    dplyr::rename(mean = .mean) %>%
    dplyr::select(time, site_id = siteID, .model, mean, sd) %>%
    tidyr::pivot_longer(c(mean, sd), names_to = "statistic", values_to = var) %>%
    pivot_longer(tidyselect::all_of(var), names_to="variable", values_to = "predicted")
}


efi_richness <- efi_statistic_format(fc_richness)
efi_abundance <-  efi_statistic_format(fc_abundance)
forecast <- bind_rows(efi_richness, efi_abundance)  



## Create the metadata record, see metadata.Rmd
theme_name <- "beetles"
time <- as.character(min(forecast$time))
team_name <- "EFInull"
filename <- paste0(theme_name, "-", time, "-", team_name, ".csv.gz")

## Store the forecast products
readr::write_csv(forecast, filename)

neon4cast::submit(forecast_file = filename, 
                  ask = FALSE)


