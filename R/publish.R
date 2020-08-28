## This function could be replaced by any other function that takes file paths
## and returns file ids


  
  
publish <-  function(files, dir ="/minio/content-store/", server = "https://minio.thelio.carlboettiger.info"){
  
  ## This particular publish function is designed for a server with MINIO
  if(!fs::file_exists(dir)) return(contentid::content_id(files))
  
  ## Add files to the store:
  ids <- lapply(files, contentid::store, )
  ## This content-store made public via a MINIO server, so we can register those URLs
  suppressWarnings({ ## need to vectorize `retreive` and `store`
  urls <- gsub("^/minio", server,
               contentid::retrieve(ids, dir = dir))
  })
  ## Register those URLs
  contentid::register(urls, "https://hash-archive.org")
}

