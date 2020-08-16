

# depends: vroom, openssl, emld

prefix="hash://sha256/"

# `tables` is a list(list(file="data.csv", description = "da da da"), list(...))
build_eml <- function(title, abstract, creator, tables = NULL, coverage = NULL,
                      output = "eml.xml"){
  
  dataTables <- NULL
  if(!is.null(tables))
    dataTables <- lapply(tables, function(x) build_dataTable(x$file, x$description))
  
  meta <- list(
    dataset = list(
      title = title,
      abstract = abstract,
      contact = creator,
      creator = list(references = creator$id),
      pubDate = Sys.Date(),
      intellectualRights = "https://creativecommons.org/publicdomain/zero/1.0/legalcode",
      dataTable = dataTables,
      coverage = coverage
    ),
    system = "hash-uri",
    packageId = package_id(tables))
  
  emld::as_xml(meta,  output)
  
}

package_id <- function(tables){
  ids <- vapply(tables, 
                function(x) paste0(openssl::sha256(file(x$file))),
                character(1L))
  
  hash <- paste0(openssl::sha256(paste(ids, sep="\n")))
  paste0(prefix, hash)
  
  hash
}



build_dataTable <- function(file, description){
  list(entityName = file,
       entityDescription = description,
       physical = physical(file),
       attributeList = attribute_list(file))
  
  
}


## 
physical <-  function(file,  url = NULL){
  f <- file
  hash <- paste0(openssl::sha256(file(f)))
  id <- paste0(prefix, hash)
  size <- file.size(f)
  
  compression = NULL
  if(grepl("[.]gz$", f)) compression = "gz"
  if(grepl("[.]bz2$", f)) compression = "bz2"
  
  csv_format <-
    list(textFormat = list(recordDelimiter = "\n",
                           attributeOrientation = "column",
         simpleDelimited = list(fieldDelimiter= ',',
                                quoteCharacter= '"',
                                literalCharacter= "\\")))
  
    list(
      authentication = list(
        authentication = hash,
        method = "SHA-256"),
      characterEncoding = "UTF-8",
      compressionMethod = compression,
      dataFormat = csv_format,
   #   distribution = list(online = list(onlineDescription = "Alternative/non-archival location"),
  #                        url = url),
      id = id,
      objectName = basename(f),
      size = list(size = size, unit= "bytes")
  )
}


attribute_list <- function(file){
  f <- file
  header <- vroom::vroom(f, n_max = 1)
  schema <- vroom::spec(header)
  name <- names(schema$cols)
  list(attribute = lapply(name, function(i) parse_schema(schema$cols[[i]], i)))
 
}


parse_schema <- function(col, name, definition = name){
  type <- strsplit(class(col), "_")[[1]][[2]]
  switch(type,
         "character" = char_att(name, definition),
         "date" = datetime_att(name, definition),
         "double" = numeric_att(name, definition),
         "integer" = integer_att(name, definition),
         char(name, definition)
         )
  }


datetime_att <- function(name, definition = name, format = "YYYY-MM-DD"){
  list(attributeName = name, attributeDefinition = definition, 
       measurementScale = list(dateTime = list(formatString = format)))
}

char_att <- function(name, definition = name){
  list(attributeName = name, attributeDefinition = definition, 
       measurementScale = list(nominal = list(nonNumericDomain = list(textDomain = list(definition = definition)))))
}

numeric_att <-  function(name, definition = name, unit = "dimensionless", standard = TRUE){
  unit_node = list(standardUnit = unit)
  if(!standard) unit_node = list(customUnit = unit)
  
  list(attributeName = name, attributeDefinition = definition, 
       measurementScale = list(interval = 
                                 list(unit = unit_node,
                                      numericDomain = list(numberType = "real"))
                               )
       )
}

integer_att <-  function(name, definition = name, unit = "dimensionless", standard = TRUE){
  unit_node = list(standardUnit = unit)
  if(!standard) unit_node = list(customUnit = unit)
  
  list(attributeName = name, attributeDefinition = definition, 
       measurementScale = list(interval = 
                                 list(unit = unit_node,
                                      numericDomain = list(numberType = "integer"))
       )
  )
}

# set_unitList(data.frame(id = 'unknown', unitType="dimensionless", 
#                        "parentSI"="dimensionless", "multiplierToSI" = 1, "description"="This unit ")) 
  


