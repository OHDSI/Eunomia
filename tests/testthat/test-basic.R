test_that("Dataset not downloaded and not loaded into SQLite", {
  if (file.exists(file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.zip"))) {
    unlink(file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.zip"))
  }
  if (file.exists(file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.sqlite"))) {
    unlink(file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.sqlite"))
  }
  expect_error(getConnectionDetails(datasetName = "GiBleed"), NA)
})

test_that("Dataset downloaded but not loaded into SQLite", {
  downloadEunomiaData(datasetName = "GiBleed")
  if (file.exists(file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.sqlite"))) {
    unlink(file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.sqlite"))
  }
  expect_error(getConnectionDetails(datasetName = "GiBleed"), NA)
})

test_that("Get connection details", {
  expect_s3_class(getEunomiaConnectionDetails(), "ConnectionDetails")
})

test_that("Connect", {
  connection <- DatabaseConnector::connect(getEunomiaConnectionDetails())
  expect_s4_class(connection, "DatabaseConnectorDbiConnection")
  DatabaseConnector::disconnect(connection)
})

test_that("Query", {
  connection <- DatabaseConnector::connect(getEunomiaConnectionDetails())
  personCount <- DatabaseConnector::querySql(connection, "SELECT COUNT(*) FROM main.person;")
  expect_gt(personCount, 0)
  DatabaseConnector::disconnect(connection)
})

test_that("Cohort construction", {
  connectionDetails <- getEunomiaConnectionDetails()
  capture.output(createCohorts(connectionDetails))
  connection <- DatabaseConnector::connect(connectionDetails)

  sql <- "SELECT COUNT(*)
          FROM main.cohort
          WHERE cohort_definition_id = 1;"
  cohortCount <- DatabaseConnector::renderTranslateQuerySql(connection, sql)
  expect_gt(cohortCount, 0)

  cohort <- DatabaseConnector::dbGetQuery(connection, "SELECT * FROM main.cohort;")
  expect_false(any(is.na(cohort$cohort_definition_id)))
  expect_false(any(is.na(cohort$subject_id)))
  expect_false(any(is.na(cohort$cohort_start_date)))
  expect_false(any(is.na(cohort$cohort_end_date)))

  DatabaseConnector::disconnect(connection)
  expect_false(DatabaseConnector::dbIsValid(connection))
})

# getConnectionDetails Tests --------
test_that("datasetName missing error", {
  expect_error(getConnectionDetails(pathToData = ""))
  expect_error(getConnectionDetails("GiBleed", dbms = ""))
})



