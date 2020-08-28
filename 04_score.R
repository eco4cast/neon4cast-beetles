## 04_score.R
library(tidyverse)
library(scoringRules)


## Prediction
richness_forecast <- read_csv("forecast/richness_forecast.csv")
abund_forecast <- read_csv("forecast/abund_forecast.csv")

## Targets
richness <- read_csv("targets/richness.csv")
abund <- read_csv("targets/abund.csv")


crps_score <- function(forecast,
                       target){
  
  ## Teach crps to treat NA observations as NA scores:
  scoring_fn <- function(y, dat) 
    tryCatch(scoringRules::crps_sample(y, dat), error = function(e) NA_real_, finally = NA_real_)
  
  ## Left-join will keep only the rows for which site,month,year of the target match the predicted
  left_join(forecast, target, by = c("siteID", "month", "year"))  %>% 
    mutate(id = paste(siteID, year, month, true, sep="-")) %>%
    group_by(id) %>% 
    summarise(score = scoring_fn(true[[1]], y))
}

richness_score <- crps_score(richness_forecast, richness)
abund_score <- crps_score(abund_forecast, abund)


readr::write_csv(richness_score, "score/richness_score.csv")
readr::write_csv(abund_score, "score/abund_score.csv")
publish(c("score/richness_score.csv", "score/abund_score.csv"))


