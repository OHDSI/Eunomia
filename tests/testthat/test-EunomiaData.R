# downloadEunomiaData Tests ----------
test_that("datasetName missing", {
  expect_error(downloadEunomiaData(
    datasetName = "",
    pathToData = tempfile(fileext = "foo")
  ))
})

test_that("pathToData missing", {
  expect_error(downloadEunomiaData(
    datasetName = "GiBleed",
    pathToData = ""
  ))
})

test_that("EUNOMIA_DATA_FOLDER different from folder name", {
  expect_message(downloadEunomiaData(
    datasetName = "GiBleed",
    pathToData = tempfile(fileext = "foo")
  ),
  regexp = "Consider*"
  )
})

test_that("Expected path for downloadEunomiaData", {
  expect_invisible(downloadEunomiaData(datasetName = "GiBleed"))
  expect_true(file.exists(file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.zip")))
})

test_that("Overwrite test for downloadEunomiaData", {
  expect_invisible(downloadEunomiaData(
    datasetName = "GiBleed",
    overwrite = T
  ))
  expect_true(file.exists(file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.zip")))
})

# extractLoadData Tests -----------
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


test_that("Expected path for extractLoadData", {
  downloadEunomiaData(datasetName = "GiBleed")
  expect_warning(extractLoadData(dataFilePath = file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.zip")))
  expect_true(file.exists(file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.zip")))
})
