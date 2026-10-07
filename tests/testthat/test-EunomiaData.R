test_that("datasetName missing", {
  expect_error(downloadEunomiaData(
    datasetName = "",
    pathToData = tempfile(fileext = "foo")
  ))
})

test_that("Overwrite test for downloadEunomiaData", {
  downloadedData <- downloadEunomiaData(datasetName = "GiBleed", overwrite = T)
  expect_true(file.exists(downloadedData))
})

test_that("Eunomia defaults to CDM 5.5", {
  expect_identical(formals(downloadEunomiaData)$cdmVersion, "5.5")
  expect_identical(formals(extractLoadData)$cdmVersion, "5.5")
  expect_identical(formals(loadDataFiles)$cdmVersion, "5.5")
  expect_identical(formals(getDatabaseFile)$cdmVersion, "5.5")
})

test_that("Eunomia works with 5.5", {
  databaseFile <- getDatabaseFile(datasetName = "GiBleed", cdmVersion = "5.5", overwrite = T)
  expect_true(file.exists(databaseFile))

  connection <- DBI::dbConnect(RSQLite::SQLite(), dbname = databaseFile)
  on.exit(DBI::dbDisconnect(connection), add = TRUE)
  expect_true(all(c("episode", "pack_content", "concept_metadata") %in% DBI::dbListTables(connection)))
  expect_true("value_as_source_concept_id" %in% DBI::dbListFields(connection, "measurement"))
  cdmSource <- DBI::dbGetQuery(
    connection,
    "SELECT cdm_release_identifier, cdm_release_date, cdm_version, cdm_version_concept_id FROM cdm_source"
  )
  expect_identical(cdmSource$cdm_release_identifier, "v1.2")
  expect_identical(
    as.numeric(cdmSource$cdm_release_date),
    as.numeric(as.POSIXct("2026-08-25", tz = "GMT"))
  )
  expect_identical(cdmSource$cdm_version, "v5.5")
  expect_identical(cdmSource$cdm_version_concept_id, 902984L)
  expect_true(DBI::dbExistsTable(connection, "concept"))
  versionConcept <- DBI::dbGetQuery(connection, "SELECT concept_name FROM concept WHERE concept_id = 902984")
  expect_identical(versionConcept$concept_name, "OMOP CDM Version 5.5.0")
})

test_that("Eunomia works with 5.4", {
  databaseFile <- getDatabaseFile(datasetName = "Synthea27Nj", cdmVersion = "5.4", overwrite = T)
  expect_true(file.exists(databaseFile))
})

# skip test temporarily - macos github actions issue
# test_that("Eunomia works with parquet, 5.4", {
#   databaseFile <- getDatabaseFile(datasetName="Synthea27NjParquet", cdmVersion = "5.4", inputFormat="parquet", overwrite = T)
#   expect_true(file.exists(databaseFile))
# })

test_that("Stop when data file not found", {
  expect_error(extractLoadData(dataFilePath = tempfile(fileext = "no_exists")))
})

test_that("Stop when ZIP file contains no CSV files", {
  testDir <- tempfile(fileext = "empty_zip")
  testFile <- tempfile(fileext = "somefile.txt")
  dir.create(testDir)
  readr::write_csv(x = data.frame(y = 1), file = testFile)
  utils::zip(file.path(testDir, "empty.zip"), testFile)
  expect_error(extractLoadData(dataFilePath = file.path(testDir, "empty.zip")))
})
