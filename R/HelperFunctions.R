#' List available CDM samples
#'
#' @description
#' List currently available CDM data samples in the Eumonia package
#'
#' @return
#' A data frame with two columns. The 'cdm_name' column contains the data sample name,
#' and 'description' column contains brief description of the sample content
#'
#' @examples
#' listCdmSamples()
#'
#' @export
listCdmSamples <- function(){
  pathToCsv <- system.file("csv", "cdmSamples.csv", package = "Eunomia")
  return(read.csv(pathToCsv, stringsAsFactors = FALSE))
}
