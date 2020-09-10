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
  count(siteID, month, year) %>% 
  rename(value = n)  %>%
  mutate(target = "richness",
         units = "observed_count") %>% 
  ungroup()



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
  mutate(value = count / trapnights,
         target = "abundance",
         units = "observed_count_per_trapnight") %>% 
  select(siteID, month, year, target, value, units) %>%
  ungroup()

targets <- bind_rows(abund, richness)



##  Write out the targets
write_csv(targets, "beetle-targets.csv.gz")

## Publish the targets to EFI.  Assumes aws.s3 env vars are configured.
source("R/publish.R")
publish(code = c("02_targets.R", "R/resolve_taxonomy.R"),
        data_out = "beetle-targets.csv.gz",
        prefix = "beetle/",
        bucket = "targets")




