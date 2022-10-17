# downloadEunomiaData Tests ----------
test_that("pathToData missing", {
  expect_error(downloadEunomiaData(datasetName = "GiBleed",
                                   pathToData = ""))
})

test_that("pathToData missing", {
  expect_error(downloadEunomiaData(datasetName = "GiBleed",
                                   pathToData = ""))
})
