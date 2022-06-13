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

message("Downloading: DP1.10022.001")
neonstore::neon_download(product="DP1.10022.001", 
                         type = "expanded", 
                         start_date = NA,
                         .token = Sys.getenv("NEON_TOKEN"))
neon_store(product = "DP1.10022.001")


## Load data from raw files
sorting <- neon_table("bet_sorting-expanded")
para <- neon_table("bet_parataxonomistID-expanded")
expert <- neon_table("bet_expertTaxonomistIDProcessed-expanded")
field <- neon_table("bet_fielddata-expanded")


#### Generate derived richness table  ####################
beetles <- resolve_taxonomy(sorting, para, expert) %>%
  mutate(iso_week = ISOweek::ISOweek(collectDate),
         time = ISOweek::ISOweek2date(paste0(iso_week, "-1"))) %>%
  as_tibble()

richness <- beetles %>%
  select(taxonID, siteID, collectDate, time) %>%
  distinct() %>%
  count(siteID, time) %>%
  rename(richness = n)  %>%
  ungroup()



#### Generate derived abundance table ####################

## Using 'field' instead of 'beetles' Does not reflect taxonomic corrections!
## Allows for some counts even when richness is NA

effort <- field %>%
  mutate(iso_week = ISOweek::ISOweek(collectDate),
         time = ISOweek::ISOweek2date(paste0(iso_week, "-1"))) %>%
  group_by(siteID, time) %>%
  summarise(trapnights = as.integer(sum(collectDate - setDate)),
            .groups = "drop")

counts <- beetles %>%
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

targets_na <- full_join(abund, richness)

## site-dates that have sampling effort but no counts should be
## treated as explicit observed 0s

## FIXME some may have effort but no sorting due only to latency, should not be treated as zeros

targets <- effort %>%
  select(siteID, time) %>%
  left_join(targets_na) %>%
  tidyr::replace_na(list(richness = 0L, abundance = 0))

##  Write out the targets
write_csv(targets, "beetles-targets.csv.gz")

## Publish the targets to EFI.  Assumes aws.s3 env vars are configured.
source("../challenge-ci/R/publish.R")
publish(code = c("02_targets.R", "R/resolve_taxonomy.R"),
        data_out = "beetles-targets.csv.gz",
        prefix = "beetles/",
        bucket = "targets",
        provdb = "beetles-targets-prov.tsv",
        registries = "https://hash-archive.carlboettiger.info")




