test_that("Eunomia connection details retain the default dataset and CDM version", {
  expect_identical(formals(getEunomiaConnectionDetails)$datasetName, "GiBleed")
  expect_identical(formals(getEunomiaConnectionDetails)$cdmVersion, "5.5")
})

test_that("Eunomia connection details use the requested dataset and CDM version", {
  dataFolder <- tempfile("eunomia_data_")
  databaseFile <- tempfile(fileext = ".sqlite")
  dir.create(dataFolder)
  on.exit(unlink(c(dataFolder, databaseFile), recursive = TRUE, force = TRUE), add = TRUE)
  withr::local_envvar(EUNOMIA_DATA_FOLDER = dataFolder)

  expect_true(file.create(file.path(dataFolder, "ExampleDataset_5.4.sqlite")))

  getEunomiaConnectionDetails(
    databaseFile = databaseFile,
    datasetName = "ExampleDataset",
    cdmVersion = "5.4"
  )

  expect_true(file.exists(databaseFile))
})
