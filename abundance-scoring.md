abundance
================
Carl Boettiger
2020-07-21

``` r
library(dplyr)
```

``` r
## or just use a cache committed to the repo, since it's small
bet_sorting <- readRDS("data/bet_sorting.rds")
bet_fielddata <- readRDS("data/bet_fielddata.rds")
```

## Compute ‘catch-per-unit-effort’, CPUE, by date and site

``` r
effort <- bet_fielddata %>% 
  group_by(siteID, collectDate) %>% 
  summarize(trapnights = as.integer(sum(collectDate - setDate)))
  #summarize(trapnights = sum(trappingDays))  ## Has bunch of NAs this way

counts <- bet_sorting %>%  
## Are we really aggregating all beetles regardless of species ID?  Do we want to do top 10 most abund species instead?
#  group_by(scientificName, collectDate, siteID) %>%
  group_by(collectDate, siteID) %>%
    summarize(count = sum(individualCount, na.rm = TRUE))

bet_cpue_raw <- counts %>% 
  left_join(effort) %>% 
  mutate(cpue = count / trapnights) %>% ungroup()

# damn it's takes a lot of trap nights to catch any beetles!
bet_cpue_raw
```

    ## # A tibble: 2,279 x 5
    ##    collectDate siteID count trapnights   cpue
    ##    <date>      <chr>  <dbl>      <int>  <dbl>
    ##  1 2013-07-01  CPER       1         14 0.0714
    ##  2 2013-07-02  DSNY       0        560 0     
    ##  3 2013-07-03  CPER     173        560 0.309 
    ##  4 2013-07-10  STER      13        112 0.116 
    ##  5 2013-07-11  OSBS       0        560 0     
    ##  6 2013-07-15  HARV      51        238 0.214 
    ##  7 2013-07-16  DSNY       0        448 0     
    ##  8 2013-07-16  HARV      29        189 0.153 
    ##  9 2013-07-17  CPER     276        560 0.493 
    ## 10 2013-07-17  DSNY       0         60 0     
    ## # … with 2,269 more rows

Let’s use the 2019 data as the “future” to assess forecast skill. Also,
let’s aggregate by month so it’s a bit easier to line up ‘historic’ and
‘predicted’ values over a seasonal trend.

``` r
bet_cpue <- bet_cpue_raw %>% 
  mutate(month = format(collectDate, "%Y-%m")) %>%
  mutate(month = as.Date(paste(month, "01", sep="-")))

future_cpue <- bet_cpue %>% filter(collectDate >= "2019-01-01")
train_cpue <- bet_cpue %>% filter(collectDate < "2019-01-01")
```

## Average baseline dummy forecast

Note: we average all historical months to forecast the future month, so
that our dummy forecast can still reflect seasonal variability to some
extent. Note also that for each month of a given year we usually have
two bouts of sampling, so those are also just being averaged in here.

``` r
null_forecast <- train_cpue %>% 
  mutate(month = lubridate::month(month, label=TRUE)) %>%
  group_by(month, siteID) %>%
  summarize(mu = mean(cpue, na.rm=TRUE),
            sigma = sd(cpue, na.rm=TRUE))

null_forecast
```

    ## # A tibble: 273 x 4
    ##    month siteID      mu    sigma
    ##    <ord> <chr>    <dbl>    <dbl>
    ##  1 Jan   SJER   0.0234   0.00387
    ##  2 Feb   SJER   0.00910  0.00636
    ##  3 Feb   STER   0.0893   0.0357 
    ##  4 Mar   BLAN   0.00476 NA      
    ##  5 Mar   CLBJ   0.0160   0.00858
    ##  6 Mar   DELA   0.0294  NA      
    ##  7 Mar   DSNY   0.0714  NA      
    ##  8 Mar   JERC   0.0143  NA      
    ##  9 Mar   JORN   0.00893 NA      
    ## 10 Mar   OAES   0       NA      
    ## # … with 263 more rows

## Scoring

We can easily compute a proper score for each site:

``` r
proper_score <- function(x, mu, sigma){ -(mu - x )^2 / sigma^2  - log(sigma) }


proper_scores <- future_cpue %>%
  mutate(month = lubridate::month(month, label=TRUE)) %>%
  select(month, siteID, true = cpue) %>% 
  left_join(null_forecast)  %>%
  mutate(score = proper_score(true, mu, sigma))
```

We could also compute a net score by site (summed over month) or overall
score (at least I think you’re allowed to just sum proper scores):

``` r
proper_scores %>%  group_by(siteID) %>% summarize(sum(score, na.rm = TRUE))
```

    ## `summarise()` ungrouping output (override with `.groups` argument)

    ## # A tibble: 47 x 2
    ##    siteID `sum(score, na.rm = TRUE)`
    ##    <chr>                       <dbl>
    ##  1 ABBY                        20.7 
    ##  2 BARR                         1.85
    ##  3 BART                       -86.1 
    ##  4 BLAN                        14.4 
    ##  5 BONA                      -211.  
    ##  6 CLBJ                        39.2 
    ##  7 CPER                        11.3 
    ##  8 DCFS                        20.6 
    ##  9 DEJU                        11.4 
    ## 10 DELA                        20.6 
    ## # … with 37 more rows

``` r
proper_scores %>% pull(score) %>% sum(na.rm = TRUE)
```

    ## [1] -5627.209
