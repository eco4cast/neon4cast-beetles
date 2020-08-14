

f <- "products/richness.csv"
id <- contentid::content_id(f)
url <-  gsub("^/minio", "https://minio.thelio.carlboettiger.info",
             contentid::retrieve(id, dir = "/minio/content-store/"))

me <- list(individualName = list(givenName = "Carl", surName = "Boettiger"))
eml <- list(
    dataset = list(
    title = "richness.csv",
    abstract = "Carabid beetle species richness by siteID and collectDate across all NEON sites operating pitfall traps.",
    contact = me,
    creator = me,
    intellectualRights = "https://creativecommons.org/publicdomain/zero/1.0/legalcode",
    distribution = list(online = list(onlineDescription = "", 
                                      url = url))
    ),
  system = "hash",
  packageId = paste0(id, "-meta"))


emld::as_xml(eml, "eml.xml")
emld::eml_validate("eml.xml")



csv_format <- 
  list(textFormat = list(recordDelimiter = "\n",
                         attributeOrientation = "column"),
       simpleDelimited = list(fieldDelimiter= ',',
                              quoteCharacter= '"',
                              literalCharacter= "\\"))
physical <- list(
    authentication = list(
      authentication = gsub("^https://sha256/", "", id),
      method = "SHA-256"),
    characterEncoding = "UTF-8",
    compressionMethod= "",
    dataFormat = csv_format,
    distribution = list(online = list(onlineDescription = "", url = url)),
    id = paste0("hash://sha256/", hash),
    objectName = basename(f),
    size = list(size = 60000, unit= "bytes")
)




