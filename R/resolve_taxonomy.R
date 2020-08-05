
# Update `scientificName`, `taxonID`, `taxonRank` and `morphospeciesID` using assignments from parataxonomy and expert taxonomy.
# 
library(dplyr)
resolve_taxonomy <- function(sorting, para, expert){
  
  taxonomy <-
    left_join(sorting, 
              select(para, subsampleID, individualID, scientificName, taxonRank, taxonID, morphospeciesID), 
              by = "subsampleID")  %>% 
    ## why are there so many other shared columns (siteID, collectDate, etc?  and why don't they match!?)
    ## we use `select` to avoid these
    left_join(
      select(expert, -uid, -namedLocation, -domainID, -siteID, -collectDate, -plotID, -setDate, -collectDate),
      by = "individualID") %>% 
    distinct() %>%
     ## Prefer the para table cols over the sorting table cols only for sampleType=="other carabid"
    mutate(taxonRank.x = ifelse(is.na(taxonRank.y) | sampleType != "other carabid", taxonRank.x, taxonRank.y),
           scientificName.x = ifelse(is.na(scientificName.y) | sampleType != "other carabid", scientificName.x, scientificName.y),
           taxonID.x = ifelse(is.na(taxonID.y) | sampleType != "other carabid", taxonID.x, taxonID.y),
           morphospeciesID.x =  ifelse(is.na(morphospeciesID.y) | sampleType != "other carabid", morphospeciesID.x, morphospeciesID.y)) %>%
      ## Prefer expert values where available
    mutate(taxonRank = ifelse(is.na(taxonRank), taxonRank.x, taxonRank),
           scientificName = ifelse(is.na(scientificName), scientificName.x, scientificName),
           taxonID = ifelse(is.na(taxonID), taxonID.x, taxonID),
           morphospeciesID =  ifelse(is.na(morphospeciesID), morphospeciesID.x, morphospeciesID),
           nativeStatusCode = ifelse(is.na(nativeStatusCode.y), nativeStatusCode.x, nativeStatusCode.y),
           sampleCondition = ifelse(is.na(sampleCondition.y), sampleCondition.x, sampleCondition.y)
           ) %>%
    select(-ends_with(".x"), -ends_with(".y")) %>%
    select(-individualCount)  
     ## individualCount could now be misleading, because it is tied to subsampleID, but subsampleID is repeated for each individualID
     ## Most of the time, the subsample all share the same expert ID, but not always.
     ## In cases where the subsample is split into separate taxa by experts, the "individualCount must also be split.
     ## There is no certain way to split the part of the sub-sample that was not pinned.  
     ## For computing richness alone, we do not need individualCounts anyway.
  
  
  #### Should we add a "species" column, using morphospecies or the best available?
  ## Use morphospecies if available for higher-rank-only classifications,
  ## Otherwise, binomialize the scientific name:
  taxonomy <- taxonomy %>% 
    mutate(morphospecies = 
             ifelse(taxonRank %in% c("subgenus", "genus", "family", "order") & !is.na(morphospeciesID), 
                    morphospeciesID,
                    taxadb::clean_names(scientificName)
             )
    )
  
  ## Beetles must be identified as carabids by both sorting table and the taxonomists (~3 non-Carabidae slip through in sorting)
  beetles <- taxonomy %>% 
    filter(grepl("carabid", sampleType)) %>%
    filter(family == "Carabidae" | is.na(family))
  
  beetles
}
  
