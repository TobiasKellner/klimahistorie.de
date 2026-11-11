repo <- "https://packagemanager.posit.co/cran/latest"
renv_version <- "1.2.4"
archive <- file.path(getwd(), "renv.tar.gz")
urls <- c(
  sprintf("%s/src/contrib/renv_%s.tar.gz", repo, renv_version),
  sprintf("%s/src/contrib/Archive/renv/renv_%s.tar.gz", repo, renv_version)
)
downloaded <- FALSE
for (url in urls) {
  downloaded <- tryCatch(
    {
      download.file(url, archive, mode = "wb") == 0L
    },
    error = function(e) FALSE
  )
  if (downloaded) break
}
if (!downloaded) {
  stop("Cannot download the pinned renv bootstrap package.")
}
dir.create("/opt/library", recursive = TRUE)
install.packages(archive, repos = NULL, type = "source", lib = "/opt/library")
.libPaths(c("/opt/library", .libPaths()))
lock <- renv::lockfile_read("renv.lock")
stopifnot(identical(lock$Packages$renv$Version, renv_version))
renv::restore(
  project = getwd(),
  lockfile = "renv.lock",
  library = "/opt/library",
  prompt = FALSE
)
