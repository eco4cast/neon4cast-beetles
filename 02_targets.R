## 02_process.R
##  Process the raw data into the target variable product

#renv::restore()
Sys.setenv("NEONSTORE_HOME" = "/efi_neon_challenge/neonstore")
Sys.setenv("NEONSTORE_DB" = "/efi_neon_challenge/neonstore")

library(neonstore)
library(tidyverse)
library(ISOweek)
source("R/resolve_taxonomy.R")

print(neon_dir())



## assumes data have been downloaded and stored with:
# neon_download("DP1.10022.001")
#neon_store(product = "DP1.10022.001")


## Load data from raw files
sorting <- neon_table("bet_sorting")
para <- neon_table("bet_parataxonomistID")
expert <- neon_table("bet_expertTaxonomistIDProcessed")
field <- neon_table("bet_fielddata")


#### Generate derived richness table  ####################
beetles <- resolve_taxonomy(sorting, para, expert) %>% 
  mutate(iso_week = ISOweek::ISOweek(collectDate),
         time = ISOweek::ISOweek2date(paste0(iso_week, "-1")))

richness <- beetles %>%  
  select(taxonID, siteID, collectDate, time) %>%
  distinct() %>%
  count(siteID, time) %>% 
  rename(richness = n)  %>%
  ungroup()



#### Generate derived abundance table ####################

effort <- field %>% 
  mutate(iso_week = ISOweek::ISOweek(collectDate),
         time = ISOweek::ISOweek2date(paste0(iso_week, "-1"))) %>% 
  group_by(siteID, time) %>% 
  summarise(trapnights = as.integer(sum(collectDate - setDate)),
            .groups = "drop")

counts <- sorting %>% 
  mutate(iso_week = ISOweek::ISOweek(collectDate),
         time = ISOweek::ISOweek2date(paste0(iso_week, "-1"))) %>%
  group_by(siteID, time) %>%
  summarise(count = sum(as.numeric(individualCount), na.rm = TRUE), 
            .groups = "drop")

abund <- counts %>% 
  left_join(effort) %>% 
  arrange(time) %>%
  mutate(abundance = count / trapnights) %>% 
  select(siteID, time, abundance) %>%
  ungroup()

targets <- full_join(abund, richness)



##  Write out the targets
write_csv(targets, "beetles-targets.csv.gz")

## Publish the targets to EFI.  Assumes aws.s3 env vars are configured.
source("../neon4cast-shared-utilities/publish.R")
publish(code = c("02_targets.R", "R/resolve_taxonomy.R"),
        data_out = "beetles-targets.csv.gz",
        prefix = "beetles/",
        bucket = "targets",
        registries = "https://hash-archive.carlboettiger.info")




