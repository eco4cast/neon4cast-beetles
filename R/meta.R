creator <- list(individualName = list(givenName = "Carl", surName = "Boettiger"), 
                id = "https://orcid.org/0000-0002-1642-628X")

tables <- list(
  list(file = "products/richness_forecast.csv", 
       description = "Forecast of arabid beetle species richness
          by siteID and collectDate across all NEON sites operating pitfall traps")
)
build_eml(title = "NEON Carabid Species Richness forecast", 
          abstract = "Simple forecast of Carabid beetle species richness at
                     each month at each NEON site for 2019, based on historical averages.", 
          creator = creator, 
          tables = tables)

# depends: vroom, openssl, emld


# `tables` is a list(list(file="data.csv", description = "da da da"), list(...))
build_eml <- function(title, abstract, creator, tables = NULL, coverage = NULL){
  
  dataTables <- NULL
  if(!is.null(tables))
    dataTables <- lapply(tables, function(x) build_dataTable(x$file, x$description))
  
  meta <- list(
    dataset = list(
      title = title,
      abstract = abstract,
      contact = creator,
      creator = creator,
      pubDate = Sys.Date(),
      intellectualRights = "https://creativecommons.org/publicdomain/zero/1.0/legalcode",
      dataTable = dataTables,
      coverage = coverage
    ),
    system = "hash-uri",
    packageId = package_id(tables))

  emld::as_xml(meta, file.path(dir.name(f),  "eml.xml"))
  
}

package_id <- function(tables){
  ids <- vapply(tables, 
                function(x) as.character(openssl::sha256(file(x$file))),
                character(1L))
  hash <- as.character(openssl::sha256(ids))
  paste0("hash:/sha256/", hash)
}



build_dataTable <- function(file, description){
  f <- file
  id <- contentid::content_id(f)
  
  url <-  gsub("^/minio", "https://minio.thelio.carlboettiger.info",
               contentid::retrieve(id, dir = "/minio/content-store/"))
  
  list(entityName = f,
       entityDescription = description,
       physical = physical(file, url),
       attributeList = attribute_list(file))
  
  
}


## 
physical <-  function(file, id = contentid::content_id(f),  url = NULL){
  f <- file
  hash <- as.character(openssl::sha256(file(f)))
  size <- file.size(f)
  
  
  csv_format <-
    list(textFormat = list(recordDelimiter = "\n",
                           attributeOrientation = "column"),
         simpleDelimited = list(fieldDelimiter= ',',
                                quoteCharacter= '"',
                                literalCharacter= "\\"))
  
    list(
      authentication = list(
        authentication = gsub("^https://sha256/", "", id),
        method = "SHA-256"),
      characterEncoding = "UTF-8",
      compressionMethod= "",
      dataFormat = csv_format,
      distribution = list(online = list(onlineDescription = "", url = url)),
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
  lapply(name, function(i) parse_schema(schema$cols[[i]], i))
 
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
       measurementScale = list(interval = list(unit = unit_node),
                               numericDomain = list(numberType = "real")
                               )
       )
}

integer_att <-  function(name, definition = name, unit = "dimensionless", standard = TRUE){
  unit_node = list(standardUnit = unit)
  if(!standard) unit_node = list(customUnit = unit)
  
  list(attributeName = name, attributeDefinition = definition, 
       measurementScale = list(interval = list(unit = unit_node),
                               numericDomain = list(numberType = "integer")
       )
  )
}

# set_unitList(data.frame(id = 'unknown', unitType="dimensionless", 
#                        "parentSI"="dimensionless", "multiplierToSI" = 1, "description"="This unit ")) 
  


