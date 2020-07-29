## Adapted from Kari Norman (c) 2019
## https://github.com/martaajarzyna/temporalNEON/blob/5b428dacc68630ce23bd43f4393821c3d03f34be/data-raw/beetles_processing.Rmd


library(dplyr)


################# Taxonomy #####################################

# Take the bet_sorting table, join parataxonomy table by `subsampleID`, 
# Join that to expert table by `individualID`.  
# Prefer the higher-grade scientificName and taxonRank when available.
# Unpinned beetles in the same subsample inherit the ID of that subsample (??)
# Do nothing if the multiple experts disagree.  

# resulting table has all the columns of `sorting`, plus: `individualID` and `identificationSource`.
# identificationSource indicates if the scientificName was provided by the sorting (sort), parataxonomist (pin), or expert
# 
# The resulting table will likely have more rows than the input table, because multiple the subsample is now broken up into
# individuals always.  (be cautious of what this does to the individualCount column??)
resolve_taxonomy <- function(sorting, para, expert){
  
  ## Join sorting by subsampleID, and prefer verdict of parataxonmist
  data_pin <-sorting %>% 
    left_join(
      para %>% select(subsampleID, individualID, taxonID, scientificName, taxonRank, morphospeciesID, identificationQualifier), 
      by = "subsampleID") %>%
    mutate_if(is.factor, as.character) %>%
    ## uses parataxonomy value unless it is an NA:
    mutate(taxonID = ifelse(is.na(taxonID.y), taxonID.x, taxonID.y)) %>%
    mutate(taxonRank = ifelse(is.na(taxonRank.y), taxonRank.x, taxonRank.y)) %>%
    mutate(scientificName = ifelse(is.na(scientificName.y), scientificName.x, scientificName.y)) %>%
    mutate(morphospeciesID = ifelse(is.na(morphospeciesID.y), morphospeciesID.x, morphospeciesID.y)) %>%
    mutate(identificationSource = ifelse(is.na(scientificName.y), "sort", "pin")) %>%
    mutate (identificationQualifier = ifelse(is.na(taxonID.y), identificationQualifier.x, identificationQualifier.y)) %>%
    select(-ends_with(".x"), -ends_with(".y"))
  
  
  
  #some subsamples weren't fully ID'd by the pinners, so we have to recover the unpinned-individuals
  lost_indv <- data_pin %>% 
    filter(!is.na(individualID)) %>%
    group_by(subsampleID, individualCount) %>%
    summarise(n_ided = n_distinct(individualID)) %>% 
    filter(n_ided < individualCount) %>%
    mutate(unidentifiedCount = individualCount - n_ided) %>%
    select(subsampleID, individualCount = unidentifiedCount) %>%
    left_join(sorting %>% select(-individualCount), by = "subsampleID") %>%
    mutate(identificationSource = "sort")
  
  
  
  #add unpinned-individuals back to the pinned id's, adjust the individual counts so pinned individuals have a count of 1
  data_pin <- data_pin %>%
    mutate(individualCount = ifelse(identificationSource == "sort", individualCount, 1)) %>%
    bind_rows(lost_indv)
  
  #There are ~10 individualID's for which experts ID'd more than one species (not all experts agreed), 
  ## we want to exclude those expert ID's as per Katie Levan's suggestion
  ex_expert_id <- expert %>% 
    group_by(individualID) %>% 
    filter(n_distinct(taxonID) > 1) %>% 
    pull(individualID)
  
  # Now add expert taxonomy info, where available
  data_expert <- left_join(data_pin, 
                           select(expert,
                                  individualID,taxonID,scientificName,taxonRank,identificationQualifier) %>%
                             filter(!individualID %in% ex_expert_id), #exclude ID's that have unresolved expert taxonomy
                           by = 'individualID', na_matches = "never") %>% distinct()
  
  # Replacement old taxon info with expert info, where available
  # NOTE - This is repetitive with the code snippet above, and if you want to do it this way you can just combine the calls into one chunk. BUT, you may
  #     want to do more than this, as it is *just* a replacement of IDs for individual beetles that an expert identified. If the expert identified
  #           a sample as COLSP6 instead of CARSP14, though, then all CARSP14 from that trap on that date should probably be updated to COLSP6…
  # CB: i.e. this fails to allow expert classification to trickle down to those unpinned beetles in the subsample(?)
  beetles_data <- data_expert %>%
    mutate_if(is.factor, as.character) %>%
    mutate(taxonID = ifelse(is.na(taxonID.y), taxonID.x, taxonID.y)) %>%
    mutate(taxonRank = ifelse(is.na(taxonRank.y), taxonRank.x, taxonRank.y)) %>%
    mutate(scientificName = ifelse(is.na(scientificName.y), scientificName.x, scientificName.y)) %>%
    mutate(identificationSource = ifelse(is.na(scientificName.y), identificationSource, "expert")) %>%
    mutate (identificationQualifier = ifelse(is.na(taxonID.y), identificationQualifier.x, identificationQualifier.y)) %>%
    select(-ends_with(".x"), -ends_with(".y"))
  
  beetles_data
}


## and here we go:
expert <- readRDS("data/bet_expert.rds")
para <- readRDS("data/bet_parataxonomist.rds")
sorting <- readRDS("data/bet_sorting.rds")

beetles <- resolve_taxonomy(sorting, para, expert)

