# downloadEunomiaData Tests ----------
test_that("datasetName missing", {
  expect_error(downloadEunomiaData(
    datasetName = "",
    pathToData = tempfile(fileext = "foo")
  ))
})

test_that("pathToData missing", {
  expect_warning(downloadEunomiaData(
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
  invisible(testthat::capture_output(expect_invisible(downloadEunomiaData(datasetName = "GiBleed"))))
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
  invisible(capture_output(downloadEunomiaData(datasetName = "GiBleed")))

  invisible(capture_output(
    expect_error(extractLoadData(from = file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.zip"),
                                 to = tempfile(fileext = ".sqlite")), NA)
  ))
  expect_true(file.exists(file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.zip")))


  expect_error(extractLoadData(from = file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.zip"),
                               to = tempfile(fileext = ".duckdb"),
                               dbms = "duckdb",
                               verbose = TRUE), NA)

  expect_error(
    extractLoadData(from = file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "GiBleed_5.3.blah"),
                    to = tempfile(fileext = ".sqlite"))
  )

  expect_error(
    extractLoadData(from = file.path(Sys.getenv("EUNOMIA_DATA_FOLDER"), "blah.zip"),
                    to = tempfile(fileext = ".sqlite"))
  )
})

test_that("Empty zip file produces error", {
  withr::with_tempdir({
    zipfile <- tempfile(fileext = ".zip")
    file.create("tmp")
    utils::zip(zipfile, files = "tmp")
    expect_error(extractLoadData(from = zipfile, to = tempfile()), "does not contain .CSV")
  })
})


