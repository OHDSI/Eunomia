test_that("dbConnect works with sqlite", {
  con <- DBI::dbConnect(RSQLite::SQLite(), getDatabaseFile("GiBleed", dbms = "sqlite"))

  expect_true(DBI::dbIsValid(con))
  expect_true("concept" %in% DBI::dbListTables(con))
  df <- DBI::dbGetQuery(con, "select * from main.cdm_source")
  expect_true(is.data.frame(df))

  # check that modifications are not saved
  DBI::dbWriteTable(con, "cars", cars)
  DBI::dbDisconnect(con)
  con <- DBI::dbConnect(RSQLite::SQLite(), getDatabaseFile("GiBleed", dbms = "sqlite"))
  expect_false("cars" %in% DBI::dbListTables(con))
  DBI::dbDisconnect(con)
})

test_that("dbConnect works with duckdb", {
  skip_if_not_installed("duckdb")
  con <- DBI::dbConnect(duckdb::duckdb(), getDatabaseFile("GiBleed", dbms = "duckdb"))
  expect_true(DBI::dbIsValid(con))
  expect_true("concept" %in% DBI::dbListTables(con))
  df <- DBI::dbGetQuery(con, "select * from cdm_source")
  expect_true(is.data.frame(df))

  # check that modifications are not saved
  DBI::dbWriteTable(con, "cars", cars)
  DBI::dbDisconnect(con, shutdown = TRUE)
  con <- DBI::dbConnect(RSQLite::SQLite(), getDatabaseFile("GiBleed", dbms = "sqlite"))
  expect_false("cars" %in% DBI::dbListTables(con))
  DBI::dbDisconnect(con, shutdown = TRUE)
})

test_that("MIMIC works with sqlite", {
  con <- DBI::dbConnect(RSQLite::SQLite(), getDatabaseFile("MIMIC", dbms = "sqlite"))
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  expect_true(DBI::dbIsValid(con))
  expect_true("concept" %in% DBI::dbListTables(con))
  df <- DBI::dbGetQuery(con, "select * from main.cdm_source")
  expect_true(is.data.frame(df))
})

test_that("MIMIC works with duckdb", {
  skip_if_not_installed("duckdb")
  con <- DBI::dbConnect(duckdb::duckdb(), getDatabaseFile("MIMIC", dbms = "duckdb"))
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  expect_true(DBI::dbIsValid(con))
  expect_true("concept" %in% DBI::dbListTables(con))
  df <- DBI::dbGetQuery(con, "select * from cdm_source")
  expect_true(is.data.frame(df))
})


