scoring.Rmd
================

``` r
library(contentid)
library(tidyverse)
```

Load the forecast and true values as determined by `workflow.md`:

``` r
richness_forecast <- read_csv(resolve("hash://sha256/93e741a4ff044319b3288d71c71d4e95a76039bc3656e252621d3ad49ccc8200"))
```

    ## Loading required namespace: vroom

    ## Parsed with column specification:
    ## cols(
    ##   month = col_character(),
    ##   siteID = col_character(),
    ##   mean = col_double(),
    ##   sd = col_double(),
    ##   year = col_double()
    ## )

``` r
true_richness <- read_csv(resolve("hash://sha256/b363cc598b55b4645941c99958542aa16db77363ded84544eb49c6ffe478441e"))
```

    ## Parsed with column specification:
    ## cols(
    ##   month = col_character(),
    ##   siteID = col_character(),
    ##   true = col_double()
    ## )

Create MCMC replicates from the moments in the forecast:

``` r
ids <- richness_forecast %>% mutate(id = paste(siteID, year, month, sep="-")) %>% pull(id)

richness_reps <- map_dfr(seq_along(ids), function(i) 
  data.frame(id = ids[i],
             rep = 1:500, 
             y = rnorm(500, richness_forecast$mean[[i]], richness_forecast$sd[[i]])))
```

Define the CRPS scoring function:

``` r
## lower scores are better
crps <- function(y, d){
  N <- length(d)
  s <- 0
  for(i in 1:N){
    for(j in 1:N){
      s <- s + abs(d[i] - d[j])
    }
  }
  mean(abs(d - y)) - s / (2 * N^2)
}
crps_vec <- function(y,d) vapply(y, crps, numeric(1L), d)

# samples <- rnorm(500)
# crps_vec(c(0,1), samples)
```

``` r
## assumes true_df has column 'id' to join, and 'true' with observed value
## predicted_df has replicates, grouped by 'id' indicating a unique prediction 
## (e.g. n reps at given site and time), with value labeled as `y`
crps_score <- function(predicted_df,
                       true_df,
                       scoring_fn =  crps_vec
                      ){
   left_join(predicted_df, true_df)  %>% 
    group_by(id) %>% 
    summarise(score = crps(true, y))
}
```

``` r
true_richness <- true_richness %>% mutate(id = paste(siteID, 2019, month, sep="-"))
scores_crps <- crps_score(richness_reps, true_richness)
```

    ## Joining, by = "id"

    ## `summarise()` ungrouping output (override with `.groups` argument)

## Using moment closure, Gneiting & Raferty Eq 27:

``` r
## note, bigger scores are better here
score <- function(predicted_df,
                  true_df,
                  scoring_fn =  function(x, mu, sigma){ -(mu - x )^2 / sigma^2  - log(sigma)}
                  ){
  true_df %>% 
  left_join(predicted_df)  %>%
  mutate(score = scoring_fn(true, mean, sd))
}
```

``` r
richness_score <- score(richness_forecast, true_richness)

## average the scores when we have 2 observations in the same month(?)
eq27 <- richness_score  %>% mutate(id = paste(siteID, year, month, sep="-")) %>%
  group_by(id) %>% summarise(score = mean(score))
```

## Compare best & worst predictions under the two scoring metrics:

Combined scores, sorting by best CRPS score (using `neg_crps` so that
bigger is better in both cases)

``` r
combined <- scores_crps %>% 
  mutate(neg_crps = - score) %>% 
  select(-score) %>%
  left_join(eq27, by="id") %>%
  rename(eq27 = score) %>%
  arrange(desc(neg_crps))

combined
```

    ## # A tibble: 270 x 3
    ##    id            neg_crps    eq27
    ##    <chr>            <dbl>   <dbl>
    ##  1 JORN-2019-Oct   -0.205  0.203 
    ##  2 JORN-2019-Apr   -0.213  0.216 
    ##  3 HEAL-2019-Aug   -0.239  0.0485
    ##  4 DELA-2019-May   -0.297 -0.201 
    ##  5 SOAP-2019-May   -0.298 -0.153 
    ##  6 JORN-2019-May   -0.323 -0.158 
    ##  7 BONA-2019-Jul   -0.323 -0.25  
    ##  8 MOAB-2019-May   -0.324 -0.291 
    ##  9 BARR-2019-Jul   -0.325 -0.269 
    ## 10 ABBY-2019-Sep   -0.326 -0.267 
    ## # … with 260 more rows

Best-predicted observations:

``` r
# CRPS, small is best
scores_crps %>% arrange(score)
```

    ## # A tibble: 270 x 2
    ##    id            score
    ##    <chr>         <dbl>
    ##  1 JORN-2019-Oct 0.205
    ##  2 JORN-2019-Apr 0.213
    ##  3 HEAL-2019-Aug 0.239
    ##  4 DELA-2019-May 0.297
    ##  5 SOAP-2019-May 0.298
    ##  6 JORN-2019-May 0.323
    ##  7 BONA-2019-Jul 0.323
    ##  8 MOAB-2019-May 0.324
    ##  9 BARR-2019-Jul 0.325
    ## 10 ABBY-2019-Sep 0.326
    ## # … with 260 more rows

``` r
# eq27: Bigger is better:
eq27 %>% arrange(desc(score))
```

    ## # A tibble: 260 x 2
    ##    id              score
    ##    <chr>           <dbl>
    ##  1 JORN-2019-Apr  0.216 
    ##  2 JORN-2019-Oct  0.203 
    ##  3 HEAL-2019-Aug  0.0485
    ##  4 SOAP-2019-May -0.153 
    ##  5 JORN-2019-May -0.158 
    ##  6 DELA-2019-May -0.201 
    ##  7 BONA-2019-Jul -0.25  
    ##  8 ABBY-2019-Sep -0.267 
    ##  9 BARR-2019-Jul -0.269 
    ## 10 MOAB-2019-May -0.291 
    ## # … with 250 more rows

Worst-predicted:

``` r
scores_crps %>% arrange(desc(score))
```

    ## # A tibble: 270 x 2
    ##    id            score
    ##    <chr>         <dbl>
    ##  1 NOGP-2019-Aug  9.06
    ##  2 KONA-2019-Sep  8.35
    ##  3 STEI-2019-Oct  7.94
    ##  4 SERC-2019-Jun  7.22
    ##  5 CPER-2019-Oct  7   
    ##  6 SERC-2019-Aug  6.61
    ##  7 SCBI-2019-Sep  6.05
    ##  8 WOOD-2019-Sep  5.83
    ##  9 LENO-2019-May  5.75
    ## 10 NIWO-2019-Jun  5.68
    ## # … with 260 more rows

``` r
eq27 %>% arrange(score)
```

    ## # A tibble: 260 x 2
    ##    id            score
    ##    <chr>         <dbl>
    ##  1 KONA-2019-Sep -42.8
    ##  2 BONA-2019-Jun -42.2
    ##  3 DEJU-2019-May -40.2
    ##  4 YELL-2019-Jul -26.2
    ##  5 ABBY-2019-Jul -21.7
    ##  6 STEI-2019-Oct -20.6
    ##  7 NOGP-2019-Aug -19.4
    ##  8 SOAP-2019-Jul -17.6
    ##  9 GRSM-2019-May -16.1
    ## 10 RMNP-2019-Jul -13  
    ## # … with 250 more rows
