abundance
================
Carl Boettiger
2020-07-21

``` r
library(dplyr)
```

``` r
bet_sorting <- readRDS("data/bet_sorting.rds")
```

## Compute observed richness

``` r
richness <- bet_sorting %>%  
  select(taxonID, siteID, collectDate) %>%
  distinct() %>%
  count(siteID, collectDate)

richness
```

    ## # A tibble: 2,279 x 3
    ##    siteID collectDate     n
    ##    <chr>  <date>      <int>
    ##  1 ABBY   2016-09-13     15
    ##  2 ABBY   2016-09-27     14
    ##  3 ABBY   2017-05-03     15
    ##  4 ABBY   2017-05-17     21
    ##  5 ABBY   2017-05-31     20
    ##  6 ABBY   2017-06-14     17
    ##  7 ABBY   2017-06-28     21
    ##  8 ABBY   2017-07-12     16
    ##  9 ABBY   2017-07-26     15
    ## 10 ABBY   2017-08-09     12
    ## # … with 2,269 more rows

Let’s use the 2019 data as the “future” to assess forecast skill. Also,
let’s aggregate by month so it’s a bit easier to line up ‘historic’ and
‘predicted’ values over a seasonal trend.

``` r
richness <- richness %>% 
  mutate(month = format(collectDate, "%Y-%m")) %>%
  mutate(month = as.Date(paste(month, "01", sep="-")))

future<- richness %>% filter(collectDate >= "2019-01-01")
train <- richness %>% filter(collectDate < "2019-01-01")
```

## Average baseline dummy forecast

Note: we average all historical months to forecast the future month, so
that our dummy forecast can still reflect seasonal variability to some
extent. Note also that for each month of a given year we usually have
two bouts of sampling, so those are also just being averaged in here.

``` r
null_forecast <- richness %>% 
  mutate(month = lubridate::month(month, label=TRUE)) %>%
  group_by(month, siteID) %>%
  summarize(mu = mean(n, na.rm=TRUE),
            sigma = sd(n, na.rm=TRUE))

null_forecast
```

    ## # A tibble: 298 x 4
    ##    month siteID    mu sigma
    ##    <ord> <chr>  <dbl> <dbl>
    ##  1 Jan   SJER    3.38  1.60
    ##  2 Feb   SJER    3.33  1.21
    ##  3 Feb   STER    1.25  0.5 
    ##  4 Mar   BLAN    6.5   4.95
    ##  5 Mar   CLBJ    5.5   3.02
    ##  6 Mar   DELA    3    NA   
    ##  7 Mar   DSNY   10     1.41
    ##  8 Mar   JERC    7    NA   
    ##  9 Mar   JORN    4    NA   
    ## 10 Mar   OAES    3     2.83
    ## # … with 288 more rows

## Scoring

We can easily compute a proper score for each site:

``` r
proper_score <- function(x, mu, sigma){ -(mu - x )^2 / sigma^2  - log(sigma) }


proper_scores <- future %>%
  mutate(month = lubridate::month(month, label=TRUE)) %>%
  select(month, siteID, true = n) %>% 
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
    ##  1 ABBY                       -14.4 
    ##  2 BARR                        -5.53
    ##  3 BART                       -19.6 
    ##  4 BLAN                       -30.1 
    ##  5 BONA                        -7.64
    ##  6 CLBJ                       -25.6 
    ##  7 CPER                       -26.7 
    ##  8 DCFS                       -14.2 
    ##  9 DEJU                        -4.40
    ## 10 DELA                       -17.1 
    ## # … with 37 more rows

``` r
proper_scores %>% pull(score) %>% sum(na.rm = TRUE)
```

    ## [1] -930.1496
