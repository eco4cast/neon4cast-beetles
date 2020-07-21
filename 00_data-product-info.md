
---
title: "EFI carabids data format, structure, and issues"
author: "EFI carabid challenge team"
date: "7/21/2020"
output: html_document
---


### NEON data product DP1.0022.001: [Ground beetles sampled from pitfall traps](https://data.neonscience.org/data-products/DP1.10022.001)

This is a brain dump with helpful information for understanding NEON's carabid data products, from experimental design to data structure

#### Experimental design  
* Since 2014 to 2017, 4 traps per plot, 10 plots per site, at all terrestrial sites, summed up to 40 traps per NEON site; eaach trap in a given plot oriented towards the one of the four cardinal directions.
* 2018 onward, the northward trap was eliminated from all plots across all NEON sites, resulted in 30 traps per site.      
* Collection frequency is biweekly (every 12-14th day within the sampling bout).  
    *~~Maximum~~ An average of 11 collection bouts per year. 
    * Burning or a storm/hurricanes can lead to data gaps in within the bout
    * Precise number of bouts per year vary in response to growing season length
        * fewest bout: Alaska Jun - Aug, 3 bouts
        * most bouts: Klemme Range Research Station, OK, Mar - Nov, 19 bouts
        * max of 13 bouts for tropical domains 4 & 20

* start and end dates within a year are determined on greenness and leaf senescence determined from MODIS data
    * 2013 to 2015: trapping began when 10-day running average low temperature was >4°C and end when it was <4°C. 

* Sampling season: increasing green-up (start date) and the mid-point between decreasing greenness and minimum greenness (end date). 
    * If sites experience two peak greens, the start date is based on the first cycle of greening and the end date is based on the second cycle. 
    * If temperature is unusually cold (<4C), then initial sampling can be delayed or stopped earlier than in previous years
    * No additional sampling will be carried out if the temperature remains higher than normal
    


* plots will usually stay the same at each site through time, though these are subject to change (e.g. at NIWO, plot 004 was switched for plot 013 in 2017)

##### Plot layout 
* this is the layout of a plot
        * ![plot_carab](figures/plot_carab.png)

#### sorting, filtering, and ID
* After collection, the samples are separated into carabids and bycatch (both vert and other invert) amd subsequently, carabids samples are identified at multiple levels of expertise. 
* Sorted & IDed by feild tech => subset of sorted  pinned (parataxonomist) and re-IDed => subset of pinned to expert taxonomists  => subset to DNA bardocing
* Taxonomic expert's ID overrides identifications by the sorter and pinner.  
* Abundances are recorded by the sorting technician on the original sample and are not preserved across the different levels of ID. 
* For example, a sample of 200 individuals IDed as species A was sent to the pinner. Pinner IDs two new species (B and C) within that sample. Likewise, the     expert validates A, B, and C and adds two more species D and E. Niether expert nor parataxonomist record which individuals are B, C, D, and E. We have to     assume that only a single individual was identified for each of those new species, and the remaining individuals were correctly identified originally. 
    * abundance for species B, C, D, E = 1
    * abundance for species A = Relative abundance documented by sorting tech (100) - no of new species IDed by pinner and experts (4).

    
      * ![workflow figure](figures/datacollectionworkflow_fromNEONbeetleuserGuide.png)  
    Sample processing workflow. Source: NEON beetle User Guide

#### Data structure
* data resolution
    * ID data is recorded at trap resolution
    * finest temporal resoluton: `daysOfTrapping`, the range between `setDate` and `collectDate` per bout
* the data product splits into 9 dataframes  
      * 5 dataframes for data  
        * `bet_fielddata` - 75 day latency.  One record expected per sampleID for all of time; max of one record per trapID per plotID per collectDate.
        * `bet_sorting` - 330 day latency. One record expected per subsampleID for all of time. One row per taxa per trapID per plotID per collectDate. Carabid subsamples may generate zero or more children in the bet_parataxonomistID table
        * `bet_parataxonomistID` - 330 day latency. one row per individual beetle pinned. One record expected per individualID for all of time. The number of             individualIDs
pulled from a given subsampleID should not exceed the individualCount given in the `bet_sorting` table.
        * `bet_archivepooling` - 330 day latency. one row per pooled archive vial (archiveID), which is a mixture of subsampleIDs. Not all subsampleID’s from `bet_sorting` contribute to mixtures; some are pinned or maintained
at the trap-level.  
        * `bet_expertTaxonomistIDProcessed` - 600 day latency. one row per individual beetle professionally identified
    * 4 dataframes for metadata  
        * `categoricalCodes_10022` - spells out what each level for a categorical variable in a 'data' dataframe means  
        * `readme_10022`   
        * `validation_10022`   
        * `variables_10022` - super helpful, describes each variable in the 'data' dataframes   
* a sample is one collection at a trap
* the `trapID ` variable is contained in `bet_fielddata`, `bet_parataxonomistID`, and `bet_sorting`  
    * `bet_parataxonomistID`, and `bet_sorting` have NAs in trapID  
* the `uid` variable is unique to each dataframe - do not try joining dataframes by `uid`
* Lots of useful information on data structure included in the User Guide pdf linked in the data product webpage  
* ID: if confident about the genus of a specimen and uncertain about the species level ID => ‘cf. species’ or ‘aff. species’ 
    * indicates that the identification provided in `scientificName` is possibly incorrect
    * Cryptic species: when two species that are morphologically indistinguishable, `scientificName` lists likely species pairs where the species epithet is          seperated by `/`.
    * if `scientificName` contains `sp.` => all individuals of that group likely belong to a single species; `spp.` -> all individuals can belong to multiple         species, even multiple genera 
* `MorphoSpecies`: assigned by parataxonomists. Beetles morphologically similar, BUT, cannot assign a `scientificName`. 
    * `morphoSpecies` are split or merged after DNA barcoding or expert ID.
    * 

#### data quirks
* If all traps were not recovered from a given plot on the same day within a bout (the traps collected on the 12th day will be reset), the remaining traps        will be collected the following day BUT the traps will not be reset on the date of collection. The reset will be delayed until the start of the new bout      for the traps will delayed collection dates
* Sampling days/No of bouts across years for a site may not be uniform. 
    * if temeprature drops <4C before the regular end of the sampling season, surveyscollection stops
    * if temeprature remains <4C even after or at the regular initiation of trap collection, trapping is delayed until temeprature >4C
* accuracy in species ID: 
    * Across all sites for all bouts/samples, per species, parataxonomist ID agree with that of experts >90% of the time. 
    * For most sites, the species ID agreement between parataxonomists vs experts is 100%
    * 100% incorrect ID is limited to a handful species recorded from a few sites
    * Domain 10: trapping truncated mid-season
    * Domain 12: if >=5 instances of trap predation are observed within a single collection bout => site-wide temporary trap closures for two bouts (28 days)


#### Misc
* There is also a NEON data product for carabid DNA barcoding, but that product is outside the scope of this first forecasting challenge round.  

    
    





