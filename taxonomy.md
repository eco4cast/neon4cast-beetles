taxonomy
================
Carl Boettiger
2020-07-21

``` r
library(dplyr)
para <- readRDS("data/bet_parataxonomist.rds")
sorting <- readRDS("data/bet_sorting.rds")
field <- readRDS("data/bet_fielddata.rds")
```

Observe that `subsampleID` is unique in the sorting table, and is also
found in the parataxonomy table.

``` r
sorting %>% count(subsampleID, sort = TRUE) # most frequent occurrence of any id is 1
```

    ## # A tibble: 134,012 x 2
    ##    subsampleID                                      n
    ##    <chr>                                        <int>
    ##  1 /1y4Qq6yNwc9K5pmpvmVv8P5L5lQbBQVMSDWb+c55lo=     1
    ##  2 /1y4Qq6yNweGGfPHuurQPMsswXdeAC/ZweulEX2iKoo=     1
    ##  3 /1y4Qq6yNweGGfPHuurQPPim8hGZ0sYaf4Nijz5QT4Q=     1
    ##  4 /1y4Qq6yNweSKUgDTxpb2A8ZmhNwErO43ZLy4mzh3FM=     1
    ##  5 /GTfODrTLSw6ze32OfoFBbkgurWLfQZHmjbu2pMKkg0=     1
    ##  6 /GTfODrTLSw6ze32OfoFBbQHKbRIOuvBVUEXTRtghto=     1
    ##  7 /GTfODrTLSw6ze32OfoFBc/g+G3vNvdHOFhSvYYNAyk=     1
    ##  8 /GTfODrTLSw6ze32OfoFBc3hZ5mu7CZde37pzV7cPDc=     1
    ##  9 /GTfODrTLSw6ze32OfoFBc5fvQp5ygXduXukKeOhWcE=     1
    ## 10 /GTfODrTLSw6ze32OfoFBe41VIm5j076lkPHlme8dpQ=     1
    ## # … with 134,002 more rows

This makes it a good key value to join on. Note we *MUST NOT* join on
the other columns, which can differ between the tables\!

Observe that many species that could not be identified by the sorters
have been identified by the para-taxonomists (and thus do not get a
morpho-species assigned by the parataxonomist.) Note that the `.x`
indicates a column from the sorting table, and the `y` from the
parataxonomy table.

``` r
taxa <- sorting %>% left_join(para, by = "subsampleID")
taxa %>% select(scientificName.x, scientificName.y, morphospeciesID.x, morphospeciesID.y, taxonID.x, taxonID.y, taxonRank.x, taxonRank.y)
```

    ## # A tibble: 163,758 x 8
    ##    scientificName.x scientificName.y morphospeciesID… morphospeciesID… taxonID.x
    ##    <chr>            <chr>            <chr>            <chr>            <chr>    
    ##  1 Pterostichus ro… Pterostichus ro… <NA>             <NA>             PTEROS   
    ##  2 <NA>             <NA>             <NA>             <NA>             <NA>     
    ##  3 Pterostichus ad… Pterostichus ad… <NA>             <NA>             PTEADO   
    ##  4 Pterostichus ad… Pterostichus ad… <NA>             <NA>             PTEADO   
    ##  5 Sphaeroderus ca… Sphaeroderus ca… <NA>             <NA>             SPHCAN1  
    ##  6 Carabidae sp.    Agonum retractum <NA>             <NA>             CARSP14  
    ##  7 Carabidae sp.    Calathus ingrat… <NA>             <NA>             CARSP14  
    ##  8 Carabidae sp.    Pterostichus ro… <NA>             <NA>             CARSP14  
    ##  9 Carabidae sp.    Pterostichus pe… <NA>             <NA>             CARSP14  
    ## 10 Carabidae sp.    Pterostichus ro… <NA>             <NA>             CARSP14  
    ## # … with 163,748 more rows, and 3 more variables: taxonID.y <chr>,
    ## #   taxonRank.x <chr>, taxonRank.y <chr>

How many species of carabid did the sorting step fail to classify to at
least the species level?

``` r
taxa %>% filter(grepl("carabid", sampleType)) %>% count(taxonRank.x)
```

    ## # A tibble: 8 x 2
    ##   taxonRank.x      n
    ##   <chr>        <int>
    ## 1 family        7144
    ## 2 genus         1830
    ## 3 species      74472
    ## 4 speciesgroup   150
    ## 5 subfamily        1
    ## 6 subgenus      1742
    ## 7 subspecies    6186
    ## 8 tribe           34

``` r
unclassified <- taxa %>% filter(grepl("carabid", sampleType), taxonRank.x %in% c("family", "genus"))
```

Let’s focus on those 8,974 unclassified beetles. How many have the not
been classified by the parataxonomists?

``` r
unclassified %>% count(taxonRank.y)
```

    ## # A tibble: 6 x 2
    ##   taxonRank.y     n
    ##   <chr>       <int>
    ## 1 family       3397
    ## 2 genus        1874
    ## 3 species      3241
    ## 4 subgenus        5
    ## 5 subspecies    110
    ## 6 <NA>          347

Of those 8,974, 3397 still remain unclassified at the family level, and
another 1874 at the genus level (so about 41% were successfully
identified). But also note that the parataxonomists have been able to at
least give morphospecies ids to nearly all (only 100 have no
`morphospeciesID.y`, though some of these have `morphospeciesID.x` so
possibly the parataxonomist was questing that call). Also note that
almost all of those have “remarks” with what looks to be a guess for the
species ID (i.e. could be a good proxy for the morphospecies)

``` r
unclassified %>% filter(taxonRank.y == "family", is.na(morphospeciesID.y)) %>% select(scientificName.y, remarks.y)
```

    ## # A tibble: 100 x 2
    ##    scientificName.y remarks.y                                 
    ##    <chr>            <chr>                                     
    ##  1 Carabidae sp.    <NA>                                      
    ##  2 Carabidae spp.   This beetle is Harpalus rubripes or harrub
    ##  3 Carabidae spp.   Cyclotrachelus incises (cycinc)           
    ##  4 Carabidae spp.   Cyclotrachelus incises (cycinc)           
    ##  5 Carabidae spp.   Cyclotrachelus incisus (cycinc)           
    ##  6 Carabidae spp.   Cyclotrachelus incisus (cycinc)           
    ##  7 Carabidae spp.   Harpalus rubripes (harrub)                
    ##  8 Carabidae spp.   Harpalus rubripes (harrub)                
    ##  9 Carabidae spp.   Harpalus rubripes (harrub)                
    ## 10 Carabidae spp.   Cyclotrachelus incisus - cycinc           
    ## # … with 90 more rows

Joining on the expert table maybe more of these can be identified.
