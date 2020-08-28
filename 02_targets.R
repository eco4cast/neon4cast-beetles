## 02_process.R
##  Process the raw data into the target variable product

library(neonstore)
library(tidyverse)
source("R/resolve_taxonomy.R")

## Load data from raw files
sorting <- neon_read("bet_sorting", altrep = FALSE)
para <- neon_read("bet_parataxonomistID", altrep = FALSE)
expert <- neon_read("bet_expertTaxonomistIDProcessed", altrep = FALSE)
field <- neon_read("bet_fielddata", altrep = FALSE)


#### Generate derived richness table  ####################

beetles <- resolve_taxonomy(sorting, para, expert) %>% 
  mutate(month = lubridate::month(collectDate, label=TRUE),
         year =  lubridate::year(collectDate))

richness <- beetles %>%  
  select(taxonID, siteID, collectDate, month, year) %>%
  distinct() %>%
  count(siteID, month, year)



#### Generate derived abundance table ####################

effort <- field %>% 
  group_by(siteID, collectDate) %>% 
  summarize(trapnights = as.integer(sum(collectDate - setDate)))

counts <- sorting %>% 
  mutate(month = lubridate::month(collectDate, label=TRUE),
         year =  lubridate::year(collectDate)) %>%
  group_by(siteID, year, month) %>%
  summarize(count = sum(individualCount, na.rm = TRUE))

abund <- counts %>% 
  left_join(effort) %>% 
  mutate(abund = count / trapnights) %>% ungroup()


base <- Sys.getenv("MINIO_BUCKET", ".")
richness.csv <- file.path(base, "targets/beetle/richness.csv.gz")
abund.csv <- file.path(base, "targets/beetle/abund.csv.gz")
readr::write_csv(richness, richness.csv)
readr::write_csv(abund, abund.csv)

source("R/publish.R")

