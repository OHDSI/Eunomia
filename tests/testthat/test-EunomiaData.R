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

test_that("Eunomia works with 5.4", {
  databaseFile <- getDatabaseFile(datasetName="Synthea27Nj", cdmVersion = "5.4", overwrite = T)
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
