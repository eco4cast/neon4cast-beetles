## here we go:

#remotes::install_github("eco4cast/neon4cast")
library(neon4cast)

forecast_file <- "https://data.ecoforecast.org/forecasts/beetles/beetles-2020-01-01-EFI_avg_null.csv.gz"
score(forecast_file, "beetles")

