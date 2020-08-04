## This function could be replaced by any other function that takes file paths
## and returns file ids
  
  
publish_minio <-  function(files){
  
  ## This particular publish function is designed for a server with MINIO
  if(!fs::file_exists("/minio/shared-data")) return(contentid::content_id(files))
  
  ## Add files to the store:
  ids <- lapply(files, contentid::store, "/minio/content-store/")
  ## This content-store made public via a MINIO server, so we can register those URLs
  suppressWarnings({ ## need to vectorize `retreive` and `store`
  urls <- gsub("^/minio", "https://minio.thelio.carlboettiger.info",
               contentid::retrieve(ids, dir = "/minio/content-store/"))
  })
  ## Register those URLs
  contentid::register(urls, "https://hash-archive.org")
}

publish_dataone <- function(file){
  
  
  id <- as.character(content_id(file))
  
  library(dataone)
  library(datapack)
  d1c <-  dataone::D1Client("STAGING", "urn:node:mnStageUCSB2") # just trying to test right now
  
  # Build a DataObject containing the csv, and upload it to the Member Node
  d1Object <- new("DataObject", id, format="text/csv", filename=file)
  dataone::uploadDataObject(d1c, d1Object, public=TRUE)
  
}

# id <- "hash://md5/e27c99a7f701dab97b7d09c467acf468"
resolve_dataone <- function(id, url_only = FALSE){
  
  hash <- gsub("^hash://\\w+/", "", id)
  query <- paste0(
  "https://cn.dataone.org/cn/v2/query/solr/",
  "?q=checksum:",hash,
  "&fl=identifier,size,formatId,checksum,checksumAlgorithm,replicaMN,dataUrl&rows=10&wt=json"
  )
  resp <- httr::GET(query)
  out <- httr::content(resp)
  sources <- vapply(out$response$docs, `[[`, character(1L), "dataUrl")
  
  ## only need one source since hashes match.
  
  if(url_only) return(sources[[1]])
  
  ## add to local store and return id
  id <- contentid::store(sources[[1]])
  contentid::retrieve(id)
}


publish <- publish_minio
  