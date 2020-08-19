## This function could be replaced by any other function that takes file paths
## and returns file ids
  
  
publish <-  function(files){
  
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

