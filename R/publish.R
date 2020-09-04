
library(contentid)
library(uuid)
library(jsonld)
library(jsonlite)
library(openssl)


publish <- function(data_in, code, data_out, meta = NULL, provdb="prov.json",
                    dir = Sys.getenv("MINIO_HOME"),
                    server =  "https://data.ecoforecast.org"){
  minio_store(c(data_in,code, data_out, meta), dir, server)
  prov(data_in, code, data_out, meta, provdb)
  
  }
  
minio_store <-  function(files, dir = Sys.getenv("MINIO_HOME"), server = "https://data.ecoforecast.org"){
  
  store <- file.path(dir, "content-store")
  ## Add files to the store and retrieve paths.  (should vectorize these fns!)
  ids <- lapply(files, contentid::store, dir = store)
  paths <- lapply(ids, contentid::retrieve, dir = store)
  
  ## This content-store made public via a MINIO server, so we can 
  ## map paths into URLs and register them. 
  urls <- file.path(server, gsub(paste0("^", dir), "", paths))
  contentid::register(urls, "https://hash-archive.org")
  
}


## Identifiers are useless without some provenance metadata.
## This let's us know what we are looking for.

context <- function(){
  list(dcat = "http://www.w3.org/ns/dcat#",
       prov = "http://www.w3.org/ns/prov#", 
       dct = "http://purl.org/dc/terms/",
       id = "@id",
       type = "@type",
       identifier = list("@id" =  "dct:identifier", "@type" = "@id"),
       title = "dct:title",
       description = "dct:description",
       issued = "dct:issued",
       format = "dct:format",
       license = list("@id" =  "dct:license", "@type" = "@id"),
       creator = "dct:creator",
       compressFormat = "dcat:compressFormat",
       byteSize = "dcat:byteSize",
       wasDerivedFrom = list("@id" =  "prov:wasDerivedFrom", "@type" = "@id"),
       wasGeneratedBy = list("@id" =  "prov:wasGeneratedBy", "@type" = "@id"),
       wasGeneratedAtTime = "prov:wasGeneratedAtTime",
       used = list("@id" =  "prov:used", "@type" = "@id"),
       wasRevisionOf = list("@id" =  "prov:wasRevisionOf", "@type" = "@id"),
       isDocumentedBy = list("@id" =  "http://purl.org/spar/cito/isDocumentedBy", "@type" = "@id"),
       distribution = list("@id" =  "dcat:distribution", "@type" = "@id"),
       Dataset = "dcat:Dataset",
       Activity = "prov:Activity",
       Distribution = "dcat:Distribution",
       SoftwareSourceCode = "http://schema.org/SoftwareSourceCode")
}


write_json(list("@context"=context()), "dcat_context.json", auto_unbox=TRUE, pretty=TRUE)

hash_id <- function(f){
  if(is.null(f)) return(NULL)
  paste0("hash://sha256/", openssl::sha256(file(f, raw = TRUE)))
}

compact <- function (l) Filter(Negate(is.null), l)

dcat_distribution <- function(file, description = NULL, meta = NULL){
  
  if(is.null(file)) return(NULL)
  
  ext <- function(x) gsub(".*[.](\\w+)$", "\\1", basename(x))
  ex <- ext(file)
  compressFormat = switch(ex, 
                          "gz" = "gzip",
                          "bz2" = "bz2",
                          NULL)
  if(!is.null(compressFormat)){
    format <- mime::guess_type(gsub(compressFormat, "", file))
  } else{
    format <- mime::guess_type(file)
  }
  
  id <- hash_id(file)
  
  compact(list(
  id = id,
  type = "Distribution",
  identifier = id, 
  title = basename(file),
  description = description,
  format  = format,
  compressFormat = compressFormat,
  byteSize = file.size(file),
  isDocumentedBy = hash_id(meta)
  ))
}


multihash_id <- function(files){
  ids <- vapply(files, 
                function(x) paste0("hash://sha256/", openssl::sha256(file(x, raw=TRUE))),
                character(1L))
  paste0("hash://sha256/", paste0(openssl::sha256(paste(ids, collapse="\n"))))
}

prov <- function(data_in, code, data_out, meta = NULL, provdb="prov.json"){
  
  code_id <- hash_id(code)
  meta_id <- hash_id(meta)
  in_id <- hash_id(data_in)
  out_id <- hash_id(data_out)
  dataset_id <- multihash_id(c(data_in, code, data_out, meta))
  out <- compact(
      c(list("@context" = context()),
        type = "Dataset",
        id = dataset_id,
        issued = as.character(Sys.Date()),
        license = "https://creativecommons.org/publicdomain/zero/1.0/legalcode",
        distribution = list(compact(list(
          dcat_distribution(meta, description = "EML metadata document"),
          dcat_distribution(data_in, "Input data", meta),
          
          compact(list(type = c("Distribution", "SoftwareSourceCode"),
                       id = code_id,
                       identifier = code_id,
                       title = basename(code),
                       description = "R code",
                       format = "application/R",
                       isDocumentedBy = meta_id)),
          
          c(dcat_distribution(data_out, "output data"), list(
          wasGeneratedAtTime = file.mtime(data_out),
          wasDerivedFrom = in_id,
          wasGeneratedBy = list(type = "Activity",
                                id = paste0("urn:uuid:", uuid::UUIDgenerate()),
                                description = paste("Running R script", basename(code)),
                                used = c(in_id, code_id))
          ))
        )))
      ))
  
  
  if(file.exists(provdb)){
    tmp <- tempfile(fileext=".json")
    jsonlite::write_json(out, tmp, auto_unbox=TRUE, pretty = TRUE)
    out <- merge_jsonld(tmp, provdb)
    writeLines(out, provdb)
  } else {
    jsonlite::write_json(out, provdb, auto_unbox=TRUE, pretty = TRUE)
  }
}


## Append triples, like so:
# triple <- list(list("@id" = "hash://sha256/93e741a4ff044319b3288d71c71d4e95a76039bc3656e252621d3ad49ccc8200",
#                    "http://www.w3.org/ns/prov#wasRevisionOf" = "hash://sha256/xxxxx"))
# append_ld(triple, "prov.json")



merge_json <- function(x,y){
  m <- c(fromJSON(x, simplifyVector = FALSE), fromJSON(y, simplifyVector = FALSE))
  toJSON(m, auto_unbox = TRUE, pretty = TRUE)
}

merge_jsonld <- function(x,y, context = "meta/dcat_context.json"){
  flat_x <- jsonld::jsonld_flatten(x) 
  flat_y <- jsonld::jsonld_flatten(y)
  json <- merge_json(flat_x, flat_y)
  jsonld::jsonld_compact(json, context)
}

append_ld <- function(obj, json, context = "meta/dcat_context.json"){
  flat <- jsonld::jsonld_flatten(json) 
  flat_list <- jsonlite::fromJSON(flat, simplifyVector = FALSE)
  combined <- jsonlite::toJSON(c(flat_list, list(obj)), auto_unbox = TRUE)
  out <- jsonld::jsonld_compact(jsonld::jsonld_flatten(combined), context)
  
  writeLines(out, json)
}


