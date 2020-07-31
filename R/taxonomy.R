
# Update `scientificName`, `taxonID`, `taxonRank` and `morphospeciesID` using assignments from parataxonomy and expert taxonomy.
# 
resolve_taxonomy <- function(sorting, para, expert){
  
  taxonomy <-
    left_join(sorting, para, by = "subsampleID")  %>% 
    left_join(expert, by = "individualID") %>%
    
    ## ("Optionally") prefer the para table cols over the sorting table cols; unless those paras are NA (e.g. for unpinned subsamples)
    mutate(taxonRank.x = ifelse(is.na(taxonRank.y), taxonRank.x, taxonRank.y),
           scientificName.x = ifelse(is.na(scientificName.y), scientificName.x, scientificName.y),
           taxonID.x = ifelse(is.na(taxonID.y), taxonID.x, taxonID.y),
           morphospeciesID.x =  ifelse(is.na(morphospeciesID.y), morphospeciesID.x, morphospeciesID.y)) %>%
    ## Now, prefer expert values over sorting or para ones, where available
    mutate(taxonRank = ifelse(is.na(taxonRank), taxonRank.x, taxonRank),
           scientificName = ifelse(is.na(scientificName), scientificName.x, scientificName),
           taxonID = ifelse(is.na(taxonID), taxonID.x, taxonID),
           morphospeciesID =  ifelse(is.na(morphospeciesID), morphospeciesID.x, morphospeciesID)) %>%
    
    select(-ends_with(".x"), -ends_with(".y"))
  
  
  #### Should we add a "species" column, using morphospecies or the best available?
  ## Use morphospecies if available for higher-rank-only classifications,
  ## Otherwise, binomialize the scientific name:
  taxonomy <- taxonomy %>% 
    mutate(species = 
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
  
