#' Download Eunomia data files
#'
#' Download the Eunomia data files from https://github.com/OHDSI/EunomiaDatasets
#'
#' @param datasetName The data set name as found on https://github.com/OHDSI/EunomiaDatasets. The data
#'                    set name corresponds to the folder with the data set ZIP files
#' @param cdmVersion The OMOP CDM version. This version will appear in the suffix of the data file, for
#'                   example: <datasetName>_<cdmVersion>.zip. Default: '5.3'
#' @param pathToData The path where the Eunomia data is stored on the file system.,
#'  By default the value of the environment variable "EUNOMIA_DATA_FOLDER" is used.
#' @param method The method used for downloading files. See \code{?download.file} for details and options.
#' @return Invisibly returns the destination if the download was successful.
#' @examples
#' \dontrun{
#' downloadJdbcDrivers("GiBleed")
#' }
#' @export
getEunomiaData <- function(datasetName, cdmVersion = "5.3", pathToData = Sys.getenv("EUNOMIA_DATA_FOLDER"), method = "auto") {
  if (is.null(pathToData) || is.na(pathToData) || pathToData == "") {
    stop("The pathToData argument must be specified. Consider setting the EUNOMIA_DATA_FOLDER environment variable, for example in the .Renviron file.")
  }

  if (pathToData != Sys.getenv("EUNOMIA_DATA_FOLDER")) {
    if (Sys.getenv("EUNOMIA_DATA_FOLDER") != pathToData) {
      rlang::inform(paste0(
        "Consider adding `EUNOMIA_DATA_FOLDER='",
        pathToData,
        "'` to ",
        path.expand("~/.Renviron"), " and restarting R."
      ))
    }
  }

  if (!dir.exists(pathToData)) {
    dir.create(pathToData, recursive = TRUE)
  }

  baseUrl <- "https://github.com/OHDSI/EunomiaDatasets/blob/main/datasets"

  datasetNameVersion <- paste0(datasetName, "_", cdmVersion)
  zipName <- paste0(datasetNameVersion, ".zip")
  # downloads the file from github
  result <- download.file(
    url = paste(baseUrl, datasetName, paste0(zipName, "?raw=true"), sep = "/"),
    destfile = file.path(pathToData, zipName),
    method = method
  )

  invisible(pathToData)
}

extractLoadData <- function(dataFileName) {
  if (!file.exists(dataFileName)) {
    stop(paste0("dataFileName: ", dataFileName, " - NOT FOUND!"))
  }
  tempFileLocation <- tempfile()
  dir.create(tempFileLocation)
  utils::unzip(zipfile = dataFileName)

  # lists all the csv files and import
  temp <- list.files(path = tempFileLocation, pattern = "*.csv")
  for (i in 1:length(temp)) assign(temp[i], read.csv(temp[i]))

  unzipSuccess <- extracteddatasetName[1] == temp[1]

  if (result == 0) {
    inform(paste0("Eunomia datasets downloaded and datasets imported"))
  } else {
    abort(paste0("Download and import have failed."))
  }

  # FROM FRANK
  # options(connectionObserver = NULL)
  # options(useFancyQuotes = FALSE)

  # install.packages("RSQLite")

  connection <- DatabaseConnector::connect(dbms = "sqlite", server = "/Users/fjd/OHDSI/testload.sqlite")

  # get list of files in directory and loop through them all
  dataset_root <- "/Users/fjd/git/EunomiaDatasets/datasets/GiBleed/GiBleed_5.3"
  dataset_file <- file.path(dataset_root,"CDM_SOURCE.csv")
  dataset_tibble <- readr:::read_csv(dataset_file)

  DatabaseConnector::insertTable(
    connection = connection,
    tableName="CDM_SOURCE",
    data = dataset_tibble)

  DatabaseConnector::querySql(connection,"select * from CDM_SOURCE")


}
