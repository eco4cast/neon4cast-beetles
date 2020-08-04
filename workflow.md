Null Forecasts for the EFI NEON Community Ecology Challenge
================

This document illustrates the sequential steps for posing, producing and
scoring a forecast for the community ecology challenge:

1.  Download NEON beetle data
2.  Clean / process data into (a) richness and (b) catch-per-unit-effort
    (CPUE) data products which teams will seek to predict future values
    for
3.  Generate a dummy (null) probablistic forecast at each site, using
    historical mean and standard deviations,
4.  Score the dummy forecast

This document also shows one approach to capturing, sharing, and
‘registering’ the products associated with each step (raw data,
processed data, forecast, scores), with content-based identifiers. These
identifiers can act like DOIs but can be computed directly from the
data, and thus can be generated locally at no cost, no authentication,
and no lock-in to a specific storage provider.

``` r
library(tidyverse)

# Helper libraries for one way of managing downloads and registering products; not essential.
library(neonstore) # remotes::install_github("cboettig/neonstore")
library(contentid) # remotes::install_github("cboettig/contentid")

## Two helper functions are provided in external scripts
source("R/resolve_taxonomy.R")
source("R/publish.R")

## neonstore can cache raw data files for future reference
Sys.setenv("NEONSTORE_HOME" = "cache/")

## Set the year of the prediction.  This will be excluded from the training data and used in the forecast
forecast_year <- 2019
```

## Download data

This example uses `neonstore` to download and manage raw files locally.

``` r
## full API queries take ~ 2m.  
## full download takes ~ 5m (on Jetstream)
start_date <- NA # Update to most recent download, or NA to check all.
neonstore::neon_download(product="DP1.10022.001", start_date = start_date)
```

    ## no expanded product, using basic product

## Load data

``` r
library(neonstore)
sorting <- neon_read("bet_sorting", altrep = FALSE)
para <- neon_read("bet_parataxonomistID", altrep = FALSE)
expert <- neon_read("bet_expertTaxonomistIDProcessed", altrep = FALSE)
field <- neon_read("bet_fielddata", altrep = FALSE)
```

Publish the index of all raw data files we have used, including their
`md5sum`, for future reference. While these files are available from
NEON and the local cache, this should help us detect any changes in the
raw data, if need be.

``` r
raw_file_index <- neon_index(product="DP1.10022.001", hash = "md5")
readr::write_csv(raw_file_index, "products/raw_file_index.csv")

publish("products/raw_file_index.csv")
```

    ## [1] "hash://sha256/278a890e15871fdafe09da9af1bbba2840478f025c33b3470f0c4552b2873550"

## Process data

First, we resolve the taxonomy using the expert and parataxonomist
classification, where available. Because these products lag behind
initial identification of the `sorting` table, and because the sorting
technicians do not pin all samples (either because they are confident in
the classification already, or sample is damaged, etc), not all beetles
will have expert identification. Those with taxonomist identification
will have an `individualID` assigned. Those with expert identification
will also name the expert. Then, samples identified as non-carabids (by
either the technicians or the taxonomists) are excluded from the
dataset.

For convenience, we also add month and year as separate columns from the
`collectDate`, allowing for easy grouping.

``` r
beetles <- resolve_taxonomy(sorting, para, expert) %>% 
  mutate(month = lubridate::month(collectDate, label=TRUE),
         year =  lubridate::year(collectDate))
```

## Generate derived richness product

This example focuses on `taxonID` as the unit of taxonomy, which
corresponds to best resolved scientific name. Use `morphospecies` to
focus on species-level (binomal names only), using morphospecies where
available and where official classification was only resolved to a
higher rank. The latter results in higher observed richness.

``` r
richness <- beetles %>%  
  select(taxonID, siteID, collectDate, month, year) %>%
  distinct() %>%
  count(siteID, collectDate, month, year)

richness
```

    ## # A tibble: 2,188 x 5
    ##    siteID collectDate month  year     n
    ##    <chr>  <date>      <ord> <dbl> <int>
    ##  1 ABBY   2016-09-13  Sep    2016    14
    ##  2 ABBY   2016-09-27  Sep    2016    13
    ##  3 ABBY   2017-05-03  May    2017    10
    ##  4 ABBY   2017-05-17  May    2017    19
    ##  5 ABBY   2017-05-31  May    2017    19
    ##  6 ABBY   2017-06-14  Jun    2017    18
    ##  7 ABBY   2017-06-28  Jun    2017    22
    ##  8 ABBY   2017-07-12  Jul    2017    15
    ##  9 ABBY   2017-07-26  Jul    2017    14
    ## 10 ABBY   2017-08-09  Aug    2017    11
    ## # … with 2,178 more rows

## Generate derived CPUE product

We target a catch-per-unit-effort (CPUE) metric for abundance, e.g. to
avoid the problem of having contestants have to predict the number of
trap nights there will be. (Quite a warranted concern for 2020\! Overall
variability is over 30%, while 2018 & 2019 it is 22%.) This does suggest
the assumption that trapnights are exchangeable, but teams accounting
for things like weather on each night could still forecast raw counts
and then convert their forecast to this simpler metric.

``` r
effort <- field %>% 
  group_by(siteID, collectDate) %>% 
  summarize(trapnights = as.integer(sum(collectDate - setDate)))
  #summarize(trapnights = sum(trappingDays))  ## Has bunch of NAs this way

counts <- beetles %>%  
#  group_by(scientificName, collectDate, siteID) %>%
  group_by(collectDate, siteID, year, month) %>%
    summarize(count = sum(individualCount, na.rm = TRUE))

cpue <- counts %>% 
  left_join(effort) %>% 
  mutate(cpue = count / trapnights) %>% ungroup()


cpue 
```

    ## # A tibble: 2,188 x 7
    ##    collectDate siteID  year month count trapnights   cpue
    ##    <date>      <chr>  <dbl> <ord> <dbl>      <int>  <dbl>
    ##  1 2013-07-01  CPER    2013 Jul       1         14 0.0714
    ##  2 2013-07-03  CPER    2013 Jul    2379        560 4.25  
    ##  3 2013-07-10  STER    2013 Jul      35        112 0.312 
    ##  4 2013-07-15  HARV    2013 Jul      87        238 0.366 
    ##  5 2013-07-16  HARV    2013 Jul      47        189 0.249 
    ##  6 2013-07-17  CPER    2013 Jul    4996        560 8.92  
    ##  7 2013-07-24  STER    2013 Jul      56        168 0.333 
    ##  8 2013-07-29  HARV    2013 Jul      20        154 0.130 
    ##  9 2013-07-30  HARV    2013 Jul      70        224 0.312 
    ## 10 2013-07-31  CPER    2013 Jul    2445        560 4.37  
    ## # … with 2,178 more rows

## Publish the derived data products

Our first product is the derived data for `richness` and `cpue`. We
write the files to disk and publish them under content-based identifier.
Using <https://hash-archive.org> or `contentid::resolve()`, we could
then later resolve these IDs.

``` r
readr::write_csv(richness, "products/richness.csv")
readr::write_csv(cpue, "products/cpue.csv")


publish(c("products/richness.csv", "products/cpue.csv"))
```

    ## [1] "hash://sha256/d094e57fe31efdb5004ba2d749d2bab3dc174ed0902ff3cab04fd1d82ca3a514"
    ## [2] "hash://sha256/902d92f1bad555f35cf8dcf25e98039c350a613e07a01740755725f6fa2d2422"

## Compute (null model) Forecasts

### Baseline forecast

For the groups with only 1 data point we cannot compute `sd`, let’s use
the average `sd` of all the other data instead as our guess. Note that
some months may wind up having caught beetles in the future, even though
we have no catch in the data to date. These will end up as `NA` scores
unless we include a mechanism to convert them to estimates (e.g. we
should probably estimate a value of 0 for all months for which we have
no catch.)

To mimic scoring our forecast, we will remove data from 2019 or later.
The actual null forecast should of course omit that filter.

``` r
null_richness <- richness %>% 
    filter(year < forecast_year) %>%
  group_by(month, siteID) %>%
  summarize(mean = mean(n, na.rm = TRUE),
            sd = sd(n, na.rm = TRUE)) %>% 
  mutate(sd = replace_na(sd, mean(sd, na.rm=TRUE))) %>% 
  mutate(year = forecast_year)
```

    ## `summarise()` regrouping output by 'month' (override with `.groups` argument)

``` r
null_richness
```

    ## # A tibble: 270 x 5
    ##    month siteID  mean    sd  year
    ##    <ord> <chr>  <dbl> <dbl> <dbl>
    ##  1 Jan   SJER    3.5   1.29  2019
    ##  2 Feb   SJER    2.75  0.5   2019
    ##  3 Feb   STER    1.25  0.5   2019
    ##  4 Mar   BLAN    2     1.79  2019
    ##  5 Mar   CLBJ    5     3.16  2019
    ##  6 Mar   DELA    3     1.79  2019
    ##  7 Mar   DSNY    8     1.79  2019
    ##  8 Mar   JERC    4     1.79  2019
    ##  9 Mar   JORN    2     1.79  2019
    ## 10 Mar   ORNL    7     2.83  2019
    ## # … with 260 more rows

``` r
null_cpue <- cpue %>% 
      filter(year < forecast_year) %>%
  group_by(month, siteID) %>%
  summarize(mean = mean(cpue, na.rm=TRUE),
            sd = sd(cpue, na.rm=TRUE))  %>% 
  mutate(sd = replace_na(sd, mean(sd, na.rm=TRUE))) %>% 
  mutate(year = forecast_year)
```

    ## `summarise()` regrouping output by 'month' (override with `.groups` argument)

## Publish the forecast products

``` r
readr::write_csv(null_richness, "products/richness_forecast.csv")
readr::write_csv(null_cpue, "products/cpue_forecast.csv")

publish(c("products/richness_forecast.csv", "products/cpue_forecast.csv"))
```

    ## [1] "hash://sha256/92af71bd4837a6720794582b1e7b8970d0f57bf491be4a51e67c835802005960"
    ## [2] "hash://sha256/8fb07ad34fe4100546479cb34abf4ee1b5cfd015591cd84a77a3e7fd0d88cf4d"

## Score the forecast

``` r
## predicted_df must have columns: mean, sd, and any grouping variables (siteID, month)
## true_df must have column: 'true' and the same grouping variables with same colname and datatype
score <- function(predicted_df,
                  true_df,
                  scoring_fn =  function(x, mu, sigma){ -(mu - x )^2 / sigma^2  - log(sigma)}
                  ){
  true_df %>% 
  left_join(predicted_df)  %>%
  mutate(score = scoring_fn(true, mean, sd))
}
```

Extract the true richnesses for 2019 and compute score:

``` r
true_richness <- richness %>%
  filter(year >= forecast_year) %>%
  select(month, siteID, true = n)

richness_score <- score(null_richness, true_richness)
```

Extract the true CPUE for 2019 and compute score

``` r
true_cpue <- cpue %>%
  filter(year >= forecast_year) %>%
  select(month, siteID, true = cpue)

cpue_score <- score(null_cpue, true_cpue)
```

Note that removing `NA`s in a sum of scores is unfair, as “0” reflects a
perfect score.  
To avoid this, one option is to compute the mean score across sites:

``` r
richness_score %>% summarize(mean_score = mean(score, na.rm= TRUE))
```

    ## # A tibble: 1 x 1
    ##   mean_score
    ##        <dbl>
    ## 1      -3.44

``` r
cpue_score %>% summarize(mean_score = mean(score, na.rm= TRUE))
```

    ## # A tibble: 1 x 1
    ##   mean_score
    ##        <dbl>
    ## 1      -138.

## Publish the scores

``` r
readr::write_csv(richness_score, "products/richness_score.csv")
readr::write_csv(cpue_score, "products/cpue_score.csv")

publish(c("products/richness_score.csv", "products/cpue_score.csv"))
```


    ## [1] "hash://sha256/4976c4c8c952c82676f81ee4abf6b18c0908692f37cd52fb1b524d646d2259e7"
    ## [2] "hash://sha256/29bd155f83d553430dbe38a10e80998855206698e89a641b6d868f6ec1f8d6f5"

-----

## Retreiving products by identifier

Note that publishing a product generates a content-based identifier
(simply using the sha256 hash of the file). If the file ever changes, so
will this identifier.  
We can access any of the files published above using the identifier.
Notably, this approach is angostic to the *location* where the file is
stored, and works well with the same file stored in many locations. In
particular, we may want to copy these files over to a permanent archive
later. By registering that as just another location for the same
content, we can always use the same identifier. In this way, this
approach is compatible with DOI-based archival repositories, but lets us
separate the step of generating and registering the files from
permanently archiving them. That way, we can generate millions of copies
locally (i.e. in debugging our forecast) but not worry about writing
junk to permanent storage before we are ready to do so.

``` r
## Now anyone can later resolve these identifiers to download the content, e.g.  
richness_forecast_csv <- contentid::resolve("hash://sha256/92af71bd4837a6720794582b1e7b8970d0f57bf491be4a51e67c835802005960")
richness_forecast <- read_csv(richness_forecast_csv)
```

