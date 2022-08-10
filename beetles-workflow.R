
#remotes::install_deps()

#remotes::install_github("cboettig/neonstore")

run_full_workflow <- TRUE
generate_null <- TRUE

start_date <- NA


# Beetle
# DP1.10022.001
#message("Downloading: DP1.10022.001")
#new_data1 <- neonstore::neon_download(product="DP1.10022.001", type = "expanded", start_date = start_date, .token = Sys.getenv("NEON_TOKEN"))

  message(paste0("Generating targets at ", Sys.time()))
  source("02_targets.R")
  message(paste0("Completed targets at ", Sys.time()))
  
  if(generate_null){
    
    message(paste0("Running null at ", Sys.time()))
    #source("03_forecast.R")
    message(paste0("Completed null at ", Sys.time()))
  }




