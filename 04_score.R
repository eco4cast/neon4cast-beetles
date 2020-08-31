## 04_score.R
library(tidyverse)
library(scoringRules)
base <- Sys.getenv("MINIO_HOME", ".")


## Targets
richness <- read_csv(file.path(base, "targets/beetle/richness.csv.gz"))
abund <- read_csv(file.path(base, "targets/beetle/abund.csv.gz"))


## Read in all entries
richness_entries <- list.files(file.path(base, "forecasts"), "^beetle-richness.*\\.csv\\.gz$", full.names = TRUE)
richness_forecasts <- lapply(richness_entries, read_csv)

abund_entries <- list.files(file.path(base, "forecasts"), "^beetle-abund.*\\.csv\\.gz$", full.names = TRUE)
abund_forecasts <- lapply(abund_entries, read_csv)


crps_score <- function(forecast,
                       target){
  
  ## Teach crps to treat NA observations as NA scores:
  scoring_fn <- function(y, dat) 
    tryCatch(scoringRules::crps_sample(y, dat), error = function(e) NA_real_, finally = NA_real_)
  
  ## Left-join will keep only the rows for which site,month,year of the target match the predicted
  left_join(forecast, 
            rename(target, true = value),
            by = c("siteID", "month", "year"))  %>% 
    mutate(id = paste(siteID, year, month, sep="-")) %>%
    group_by(id) %>% 
    summarise(score = scoring_fn(true[[1]], value))
}

richness_scores <- lapply(richness_forecasts, crps_score, richness)
richness_out <- paste0(file.path(base, "scores/beetle/"), gsub("forecast", "score", basename(richness_entries)))
purrr::walk2(richness_scores, richness_out, readr::write_csv)

abund_scores <- lapply(abund_forecasts, crps_score, abund)
abund_out <- paste0(file.path(base, "scores/beetle/"), gsub("forecast", "score", basename(abund_entries)))
purrr::walk2(abund_scores, abund_out, readr::write_csv)

