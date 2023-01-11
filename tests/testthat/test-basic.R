connection <- DatabaseConnector::connect(connectionDetails)
on.exit(connection)

test_that("Get connection details", {
  if (is(connectionDetails, "connectionDetails"))
    expect_s3_class(connectionDetails, "connectionDetails")
  else
    expect_s3_class(connectionDetails, "ConnectionDetails")
})

test_that("Connect", {
  connection <- DatabaseConnector::connect(connectionDetails)
  expect_s4_class(connection, "DatabaseConnectorDbiConnection")
  DatabaseConnector::disconnect(connection)
})

test_that("Query", {
  personCount <- DatabaseConnector::querySql(connection, "SELECT COUNT(*) FROM main.person;")
  expect_gt(personCount, 0)
})

test_that("Cohort construction", {
  capture.output(createCohorts(connectionDetails))

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
})

test_that("Disconnect", {
  DatabaseConnector::disconnect(connection)
  expect_false(DatabaseConnector::dbIsValid(connection))
})

# getConnectionDetails Tests --------
test_that("datasetName missing error", {
  expect_error(getConnectionDetails(pathToData = ""))
})

test_that("Dataset not downloaded and not loaded into SQLite", {
  if (file.exists(file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.zip"))) {
    unlink(file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.zip"))
  }
  if (file.exists(file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.sqlite"))) {
    unlink(file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.sqlite"))
  }
  expect_warning(getConnectionDetails(datasetName = "GiBleed"))
})

test_that("Dataset downloaded but not loaded into SQLite", {
  downloadEunomiaData(datasetName = "GiBleed")
  if (file.exists(file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.sqlite"))) {
    unlink(file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.sqlite"))
  }
  expect_warning(getConnectionDetails(datasetName = "GiBleed"))
})
