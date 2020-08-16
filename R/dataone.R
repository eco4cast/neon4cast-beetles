

function(files, descriptions, creators){

  
  
  
dp <- new("DataPackage")
metadataObj <- new("DataObject", format="eml://ecoinformatics.org/eml-2.2.0", filename=emlFile)
dp <- addMember(dp, metadataObj)

sourceData 
sourceObj <- new("DataObject", format="text/csv", filename=sourceData) 
dp <- addMember(dp, sourceObj, metadataObj)

progFile <- system.file("extdata/filterObs.R", package="dataone")
progObj <- new("DataObject", format="application/R", filename=progFile, mediaType="text/x-rsrc")
dp <- addMember(dp, progObj, metadataObj)

outputData <- system.file("extdata/Strix-occidentalis-obs.csv", package="dataone")
outputObj <- new("DataObject", format="text/csv", filename=outputData) 
dp <- addMember(dp, outputObj, metadataObj)

myAccessRules <- data.frame(subject=orcid, permission="changePermission") 

d1c <- D1Client("STAGING", "urn:node:mnStageUCSB2")
packageId <- uploadDataPackage(d1c, dp, public=TRUE, accessRules=myAccessRules, quiet=FALSE)

}