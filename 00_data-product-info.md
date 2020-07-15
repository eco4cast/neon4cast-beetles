### NEON data product DP1.0022.001: [Ground beetles sampled from pitfall traps](https://data.neonscience.org/data-products/DP1.10022.001)

This is a brain dump with helpful information for understanding NEON's carabid data products, from experimental design to data structure

#### Experimental design   
* 4 traps per plot, 10 plots per site, at all terrestrial sites    
* Collection frequency is biweekly when temperatures are > 4 deg C.  Maximum of 13 collection bouts per year.  
* plots will usually stay the same at each site through time, though these are subject to change (e.g. at NIWO, plot 004 was switched for plot 013 in 2017)

#### Data structure
* the data product splits into 9 dataframes  
    * ![workflow figure](figures/datacollectionworkflow_fromNEONbeetleuserGuide.png)  
    Sample processing workflow. Source: NEON beetle User Guide
    * 5 dataframes for data  
        * `bet_fielddata` - 75 day latency.  One record expected per sampleID for all of time; max of one record per trapID per plotID per collectDate.
        * `bet_sorting` - 330 day latency. One record expected per subsampleID for all of time. One row per taxa per trapID per plotID per collectDate. Carabid subsamples may generate zero or more children in the bet_parataxonomistID table
        * `bet_parataxonomistID` - 330 day latency. one row per individual beetle pinned. One record expected per individualID for all of time. The number of individualIDs
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


#### Misc
* There is also a NEON data product for carabid DNA barcoding, but that product is outside the scope of this first forecasting challenge round.  
