test_that("dbConnect works with sqlite", {
  con <- DBI::dbConnect(RSQLite::SQLite(), getDatabaseFile("GiBleed", dbms = "sqlite", overwrite = T, verbose = T))
  expect_true(DBI::dbIsValid(con))
  expect_true("concept" %in% DBI::dbListTables(con))
  df <- DBI::dbGetQuery(con, "select * from main.cdm_source")
  expect_true(is.data.frame(df))
  DBI::dbDisconnect(con, shutdown=TRUE)
  duckdb::duckdb_shutdown(duckdb::duckdb())
})

test_that("dbConnect works with duckdb", {
  skip_if_not_installed("duckdb")
  con <- DBI::dbConnect(duckdb::duckdb(), getDatabaseFile("GiBleed", dbms = "duckdb", overwrite = T, verbose = T))
  expect_true(DBI::dbIsValid(con))
  expect_true("concept" %in% DBI::dbListTables(con))
  df <- DBI::dbGetQuery(con, "select * from cdm_source")
  expect_true(is.data.frame(df))
  DBI::dbDisconnect(con, shutdown=TRUE)
  duckdb::duckdb_shutdown(duckdb::duckdb())
})

# Mimic has multiple issues that can be addressed by dataset owner
#
# test_that("MIMIC works with sqlite", {
#   con <- DBI::dbConnect(RSQLite::SQLite(), getDatabaseFile("MIMIC", dbms = "sqlite", overwrite = T, verbose = T))
#   expect_true(DBI::dbIsValid(con))
#   expect_true("concept" %in% DBI::dbListTables(con))
#   df <- DBI::dbGetQuery(con, "select * from main.cdm_source")
#   expect_true(is.data.frame(df))
#   DBI::dbDisconnect(con, shutdown=TRUE)
#   duckdb::duckdb_shutdown(duckdb::duckdb())
# })
#
# test_that("MIMIC works with duckdb", {
#   skip_if_not_installed("duckdb")
#   con <- DBI::dbConnect(duckdb::duckdb(), getDatabaseFile("MIMIC", dbms = "duckdb", overwrite=T, verbose = T))
#   expect_true(DBI::dbIsValid(con))
#   expect_true("concept" %in% DBI::dbListTables(con))
#   df <- DBI::dbGetQuery(con, "select * from cdm_source")
#   expect_true(is.data.frame(df))
#   DBI::dbDisconnect(con, shutdown=TRUE)
#   duckdb::duckdb_shutdown(duckdb::duckdb())
# })


