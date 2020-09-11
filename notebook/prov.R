prov("products/richness.csv", "03_forecast.R", "products/richness_forecast.csv", "meta/eml.xml", "prov.json")
prov("products/richness_forecast.csv", "04_score.R", "products/richness_score.csv", provdb = "prov_score.json")
merge_jsonld(x, y) %>% writeLines("merged.json")

library(jsonld)
library(jsonlite)
library(magrittr)


append_ld <- function(obj, json, context = "dcat_context.json"){
  flat <- jsonld_flatten(json) 
  flat_list <- fromJSON(flat, simplifyVector = FALSE)
  
  combined <- toJSON(c(flat_list, list(obj)), auto_unbox = TRUE)
  out <- jsonld_compact(jsonld_flatten(combined), context)
  
  writeLines(out, json)
}


triple <- list(list("@id" = "hash://sha256/93e741a4ff044319b3288d71c71d4e95a76039bc3656e252621d3ad49ccc8200",
                    "http://www.w3.org/ns/prov#wasRevisionOf" = "hash://sha256/xxxxx"))


append_ld(triple, "prov.json")

jsonld_to_rdf("prov.json") %>% writeLines("prov.rdf")

## read.table can't handle RDF "40982"^^<http://www.w3.org/2001/XMLSchema#integer>
## read.table("prov.rdf", col.names  = c("subject", "predicate", "object", "graph"), comment.char = "")

df <- vroom::vroom("prov.rdf", col_names = c("subject", "predicate", "object", "graph"))
object <- vapply(df$object, function(x) strsplit(x,  "\\^\\^")[[1]][[1]], character(1L), USE.NAMES = FALSE)
type <- vapply(df$object, function(x) tryCatch(strsplit(x,  "\\^\\^")[[1]][[2]], error = function(e) NA_character_, finally=NA_character_), character(1L), USE.NAMES = FALSE)
df$object <- object
df$type <- type
df