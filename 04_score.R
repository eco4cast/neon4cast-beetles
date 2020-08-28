## 04_score.R
library(tidyverse)
library(scoringRules)
base <- Sys.getenv("MINIO_HOME", ".")

## Prediction
richness_forecast <- read_csv(file.path(base, "forecast/beetle/richness_forecast.csv.gz"))
abund_forecast <- read_csv(file.path(base, "forecast/beetle/abund_forecast.csv.gz"))

## Targets
richness <- read_csv(file.path(base, "targets/beetle/richness.csv.gz"))
abund <- read_csv(file.path(base, "targets/beetle/abund.csv.gz"))


crps_score <- function(forecast,
                       target){
  
  ## Teach crps to treat NA observations as NA scores:
  scoring_fn <- function(y, dat) 
    tryCatch(scoringRules::crps_sample(y, dat), error = function(e) NA_real_, finally = NA_real_)
  
  ## Left-join will keep only the rows for which site,month,year of the target match the predicted
  left_join(forecast, target, by = c("siteID", "month", "year"))  %>% 
    mutate(id = paste(siteID, year, month, sep="-")) %>%
    group_by(id) %>% 
    summarise(score = scoring_fn(true[[1]], y))
}

richness_score <- crps_score(richness_forecast, richness)
abund_score <- crps_score(abund_forecast, abund)

write_csv(richness_score, file.path(base, "scores/beetle/richness_score.csv.gz"))
write_csv(abund_score, file.path(base, "scores/beetle/abund_score.csv.gz"))


