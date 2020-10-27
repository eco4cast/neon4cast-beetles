## 02_process.R
##  Process the raw data into the target variable product

renv::restore()

library(neonstore)
library(tidyverse)
source("R/resolve_taxonomy.R")

print(neon_dir())

## assumes data have been downloaded and stored with:
# neon_download("DP1.10022.001")
neon_store(product = "DP1.10022.001")


## Load data from raw files
sorting <- neon_table("bet_sorting")
para <- neon_table("bet_parataxonomistID")
expert <- neon_table("bet_expertTaxonomistIDProcessed")
field <- neon_table("bet_fielddata")


#### Generate derived richness table  ####################

beetles <- resolve_taxonomy(sorting, para, expert) %>% 
  mutate(week = lubridate::week(collectDate),
         year =  lubridate::year(collectDate))

richness <- beetles %>%  
  select(taxonID, siteID, collectDate, week, year) %>%
  distinct() %>%
  count(siteID, week, year) %>% 
  rename(richness = n)  %>%
  ungroup()



#### Generate derived abundance table ####################

effort <- field %>% 
  group_by(siteID, collectDate) %>% 
  summarize(trapnights = as.integer(sum(collectDate - setDate)))

counts <- sorting %>% 
  mutate(week = lubridate::week(collectDate),
         year =  lubridate::year(collectDate)) %>%
  group_by(siteID, year, week) %>%
  summarize(count = sum(as.numeric(individualCount), na.rm = TRUE))

abund <- counts %>% 
  left_join(effort) %>% 
  arrange(collectDate) %>%
  mutate(abundance = count / trapnights) %>% 
  select(siteID, week, year, abundance) %>%
  ungroup()

targets <- full_join(abund, richness)



##  Write out the targets
write_csv(targets, "beetle-targets.csv.gz")

## Publish the targets to EFI.  Assumes aws.s3 env vars are configured.
source("R/publish.R")
publish(code = c("02_targets.R", "R/resolve_taxonomy.R"),
        data_out = "beetle-targets.csv.gz",
        prefix = "beetle/",
        bucket = "targets")




