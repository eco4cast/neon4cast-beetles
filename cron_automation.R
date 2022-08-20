library(cronR)

home_dir <- "/home/rstudio/"
log_dir <- "/home/rstudio/log/cron"

repo <- "neon4cast-beetles"

#Go to healthchecks.io. Create a project.  Add a check. Copy the url and add here.  
health_checks_url <- "https://hc-ping.com/28df2e97-6036-4fa1-9d8a-6aa9fbaa0726"

cmd <- cronR::cron_rscript(rscript = file.path(home_dir, repo, "03_forecast.R"),
                           rscript_log = file.path(log_dir, "beetles-null.log"),
                           log_append = FALSE,
                           workdir = file.path(home_dir, repo),
                           trailing_arg = paste0("curl -fsS -m 10 --retry 5 -o /dev/null ", health_checks_url))
cronR::cron_add(command = cmd, frequency = "0 12 * * MON", id = 'beetles-null')