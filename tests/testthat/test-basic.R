if (Eunomia::supportsJava8()) {
  library(testthat)
  library(Eunomia)

  connectionDetails <- getEunomiaConnectionDetails()

  test_that("Get connection details", {
    expect_s3_class(connectionDetails, "connectionDetails")
  })

  test_that("Connect", {
    connection <- DatabaseConnector::connect(connectionDetails)
    expect_s4_class(connection, "DatabaseConnectorDbiConnection")
    DatabaseConnector::disconnect(connection)
  })

  connection <- DatabaseConnector::connect(connectionDetails)

  test_that("Query", {
    personCount <-
      DatabaseConnector::querySql(connection, "SELECT COUNT(*) FROM main.person;")
    expect_gt(personCount, 0)
  })

  test_that("Cohort construction", {
    createCohorts(connectionDetails)
    sql <- "SELECT COUNT(*)
  FROM main.cohort
  WHERE cohort_definition_id = 1;"
    cohortCount <-
      DatabaseConnector::renderTranslateQuerySql(connection, sql)
    expect_gt(cohortCount, 0)
  })

  test_that("Disconnect", {
    DatabaseConnector::disconnect(connection)
    expect_false(DatabaseConnector::dbIsValid(connection))
  })

  test_that("exportToCsv works", {
    outputFolder <- file.path(tempdir(), "csv")
    expect_output(exportToCsv(outputFolder), regexp = "Done writing CSV files")
  })
}
