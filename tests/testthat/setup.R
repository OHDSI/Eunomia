# Set the EUNOMIA_DATA_FOLDER environment variable for tests
if (Sys.getenv("EUNOMIA_DATA_FOLDER", "") == "") {
  Sys.setenv("EUNOMIA_DATA_FOLDER" = tempfile("eunomiaData"))
  dir.create(Sys.getenv("EUNOMIA_DATA_FOLDER"))

  withr::defer(
    {
      unlink(Sys.getenv("EUNOMIA_DATA_FOLDER"), recursive = TRUE, force = TRUE)
    },
    testthat::teardown_env()
  )
}
