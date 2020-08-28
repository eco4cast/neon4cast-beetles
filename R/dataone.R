




library(dataone)
library(datapack)
library(mime)


dataone_node <- function(){
  if(!is.null(getOption("dataone_test_token")))
    return( dataone::D1Client("STAGING2", "urn:node:mnTestKNB") )
  dataone::D1Client("PROD", "urn:node:KNB")
}

resolve_dataone <- function(id, url_only = FALSE){
  d1c <-  dataone_node()
  paste0(d1c@cn@baseURL, "/v2/resolve/", utils::URLencode(id, TRUE))
}

## Create a data object with content-based id and a sha-256 checksum
data_object <- function(file, format = mime::guess_type(file), ...){
  library(datapack)
  hash <- paste0(openssl::sha256(file(file)))
  id <- paste0("hash://sha256/", hash)
  d1Object <- new("DataObject", id, format=mime::guess_type(file), filename=file, ...)
  
  ## Won't be needed once this is the new default, see https://github.com/DataONEorg/rdataone/issues/257
  d1Object@sysmeta@checksum <- gsub("^hash://\\w+/", "", id)
  d1Object@sysmeta@checksumAlgorithm <- "SHA-256"
  d1Object
}


publish_dataone <- function(in_file, out_file, code, meta, orcid){

  dp <- new("DataPackage")
  meta_obj <- data_object(meta, "eml://ecoinformatics.org/eml-2.2.0")
  in_obj <- data_object(in_file)
  code_obj <- data_object(code, mediaType="text/x-rsrc")
  out_obj <- data_object(out_file)
  dp <- addMember(dp, meta)
  dp <- addMember(dp, in_obj, meta)
  dp <- addMember(dp, code_obj, meta)
  dp <- addMember(dp,  out_obj, meta)
  rules <- data.frame(subject=orcid, permission="changePermission") 

  ## Add prov metadata to uploaded package
  dp <- describeWorkflow(dp, sources = in_obj, program = code_obj, 
                         derivations = out_obj)
    
  ## Will uploadDataPackage use the id from the EML already?
  packageId <- paste0("hash://sha256/",
    openssl::sha256(paste(in_obj@sysmeta@identifier,
                     code_obj@sysmeta@identifier,
                     out_obj@sysmeta@identifier,
                     sep="\n")))
  
  ## Perform the upload, requires authentication!
  repo <- dataone_node()
  id <- uploadDataPackage(repo, 
                          dp, 
                          packageId = packageId,
                          public=TRUE, 
                          accessRules=rules, 
                          quiet=FALSE)
  

  
  id
}

