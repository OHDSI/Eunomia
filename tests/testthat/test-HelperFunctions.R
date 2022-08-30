test_that("list CDM samples", {
  cdm_samples <- listCdmSamples()
  expect_s3_class(cdm_samples, "data.frame")
  expect_true("cdm_name" %in% colnames(cdm_samples))
})
