Sys.setenv("NEONSTORE_HOME" = "/efi_neon_challenge/neonstore")
Sys.setenv("MINIO_HOME" = "/efi_neon_challenge/")

dir.create(file.path(Sys.getenv("MINIO_HOME"), "targets/beetle/"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(Sys.getenv("MINIO_HOME"), "forecasts/beetle/"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(Sys.getenv("MINIO_HOME"), "scores/beetle/"), recursive = TRUE, showWarnings = FALSE)

