
  
  
publish <-  function(files, dir ="/minio/content-store/", server = "https://minio.thelio.carlboettiger.info"){
  
  ## Add files to the store and retrieve paths.  (should vectorize these fns!)
  ids <- lapply(files, contentid::store, dir)
  paths <- lapply(ids, contentid::retrieve, dir = dir)
  
  ## This content-store made public via a MINIO server, so we can 
  ## map paths into URLs and register them. 
  urls <- gsub("^/minio", server, paths)
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
       identifier = "dct:identifier",
       title = "dct:title",
       description = "dct:description",
       issued = "dct:issued",
       format = "dct:format",
       license = "dct:license",
       creator = "dct:creator",
       compressFormat = "dcat:compressFormat",
       byteSize = "dcat:byteSize",
       wasDerivedFrom = "prov:wasDerivedFrom",
       wasGeneratedBy = "prov:wasGeneratedBy",
       wasGeneratedAtTime = "prov:wasGeneratedAtTime",
       used = "prov:used",
       isRevisionOf = "prov:isRevisionOf",
       distribution = "dcat:distribution",
       Dataset = "dcat:Dataset",
       Activity = "prov:Activity",
       Distribution = "dcat:Distribution",
       isDocumentedBy = "http://purl.org/spar/cito/isDocumentedBy",
       SoftwareSourceCode = "http://schema.org/SoftwareSourceCode")
}


hash_id <- function(f){
  if(is.null(f)) return(NULL)
  paste0("hash://sha256/", openssl::sha256(file(f)))
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


prov <- function(data_in, code, data_out, meta = NULL, provfile="prov.json"){
  
  code_id <- hash_id(code)
  meta_id <- hash_id(meta)
  in_id <- hash_id(data_in)
  out_id <- hash_id(data_out)
  
  out <- 
      c(list("@context" = context()),
        type = "Dataset",
        issued = Sys.Date(),
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
                                description = paste("Running R script", basename(code)),
                                used = code_id)
          ))
        )))
      )
  jsonlite::write_json(compact(out), provfile, auto_unbox=TRUE, pretty = TRUE)
}

