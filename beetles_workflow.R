renv::restore()

library(neonstore)
library(tidyverse)


Sys.setenv("NEONSTORE_HOME" = "/efi_neon_challenge/neonstore")

run_full_workflow <- TRUE
generate_null <- TRUE

start_date <- NA


# Beetle
# DP1.10022.001
print("Downloading: DP1.10022.001")
new_data1 <- neonstore::neon_download(product="DP1.10022.001", type = "expanded", start_date = start_date, .token = Sys.getenv("NEON_TOKEN"))

if(!is.null(new_data1) | run_full_workflow){
  
  source("02_targets.R")
  
  print(paste0("Completed Target at ", Sys.time()))
  
  if(generate_null){
    
    print(paste0("Running daily Null at ", Sys.time()))
    source("03_forecast.R")
    
  }
}



