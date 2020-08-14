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

## Alias minio method as the default method, for now at least
publish <- publish_minio


## Equivalent publication interface, but using dataone
publish_dataone <- function(file){
  id <- as.character(contentid::content_id(file))
  
  library(dataone)
  library(datapack)
  d1c <-  dataone_node()
  d1Object <- new("DataObject", id, format=mime::guess_type(file), filename=file)
  d1Object@sysmeta@checksum <- gsub("^hash://\\w+/", "", id)
  d1Object@sysmeta@checksumAlgorithm <- "SHA-256"
  dataone::uploadDataObject(d1c, d1Object, public=TRUE)
  
}

# id <- "hash://md5/e27c99a7f701dab97b7d09c467acf468"
resolve_dataone_id <- function(id, url_only = FALSE){
  
  d1c <-  dataone_node()
  baseURL <- d1c@cn@baseURL
  url <- paste0(baseURL, "/v2/resolve/", URLencode(id, TRUE))
  if(url_only) return(url)
  
  ## add to local store and return id
  id <- contentid::store(sources[[1]])
  contentid::retrieve(id)
}


## simple helper function.  Use a staging portal if we have a test token,
## otherwise use the real portal. Alternately might want more explicit
## logic in env vars or options for controlling this.  
dataone_node <- function(){
  if(!is.null(getOption("dataone_test_token")))
    return( dataone::D1Client("STAGING2", "urn:node:mnTestKNB") )
  dataone::D1Client("PROD", "urn:node:KNB")
}



  
  


######################################
  
## MISC / experimental
resolve_dataone_hash <- function(id){
  hash <- gsub("^hash://\\w+/", "", id)
  d1c <-  dataone_node()
  baseURL <- d1c@cn@baseURL
  query <- paste0(baseURL, "/v2/query/solr/","?q=checksum:",hash,
  "&fl=identifier,size,formatId,checksum,checksumAlgorithm,replicaMN,dataUrl&rows=10&wt=json")
  resp <- httr::GET(query)
  out <- httr::content(resp)
  sources <- vapply(out$response$docs, `[[`, character(1L), "dataUrl")
  sources
}


  