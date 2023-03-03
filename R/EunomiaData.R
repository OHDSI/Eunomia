#' Download Eunomia data files
#' Download the Eunomia data files from https://github.com/OHDSI/EunomiaDatasets
#'
#' @param datasetName   The data set name as found on https://github.com/OHDSI/EunomiaDatasets. The
#'                      data set name corresponds to the folder with the data set ZIP files
#' @param cdmVersion    The OMOP CDM version. This version will appear in the suffix of the data file,
#'                      for example: <datasetName>_<cdmVersion>.zip. Default: '5.3'
#' @param pathToData    The path where the Eunomia data is stored on the file system., By default the
#'                      value of the environment variable "EUNOMIA_DATA_FOLDER" is used.
#' @param overwrite     Control whether the existing archive file will be overwritten should it already
#'                      exist.
#' @return
#' Invisibly returns the destination if the download was successful.
#' @examples
#' \dontrun{
#' downloadEunomiaData("GiBleed")
#' }
#' @export
downloadEunomiaData <- function(datasetName,
                                cdmVersion = "5.3",
                                pathToData = Sys.getenv("EUNOMIA_DATA_FOLDER"),
                                overwrite = FALSE) {
  if (is.null(pathToData) || is.na(pathToData) || pathToData == "") {
    stop("The pathToData argument must be specified. Consider setting the EUNOMIA_DATA_FOLDER environment variable, for example in the .Renviron file.")
  }

  if (is.null(datasetName) || is.na(datasetName) || datasetName == "") {
    stop("The datasetName argument must be specified.")
  }

  if (pathToData != Sys.getenv("EUNOMIA_DATA_FOLDER")) {
    if (Sys.getenv("EUNOMIA_DATA_FOLDER") != pathToData) {
      rlang::inform(paste0(
        "Consider adding `EUNOMIA_DATA_FOLDER='",
        pathToData,
        "'` to ",
        path.expand("~/.Renviron"),
        " and restarting R."
      ))
    }
  }

  if (!dir.exists(pathToData)) {
    dir.create(pathToData, recursive = TRUE)
  }

  datasetNameVersion <- paste0(datasetName, "_", cdmVersion)
  zipName <- paste0(datasetNameVersion, ".zip")

  if (file.exists(file.path(pathToData, zipName)) & !overwrite) {
    cat(paste0(
      "Dataset already exists (",
      file.path(pathToData, zipName),
      "). Specify overwrite=T to overwrite existing zip archive."
    ))
    invisible()
  } else {
    # downloads the file from github
    baseUrl <- "https://raw.githubusercontent.com/OHDSI/EunomiaDatasets/main/datasets"
    result <- utils::download.file(
      url = paste(baseUrl, datasetName, zipName, sep = "/"),
      destfile = file.path(
        pathToData,
        zipName
      )
    )

    invisible(pathToData)
  }
}

#' Extract the Eunomia data files and load into a SQLite database
#' Extract files from a .ZIP file and creates a SQLite OMOP CDM database that is then stored in the
#' same directory as the .ZIP file.
#'
#' @param dataFilePath   The path to the .ZIP file that contains the data
#' @examples
#' \dontrun{
#' extractLoadData("c:/strategusData/GiBleed_5.3.zip")
#' }
#' @seealso
#' \code{\link[Eunomia]{downloadEunomiaData}}
#' @export
extractLoadData <- function(dataFilePath) {
  if (!file.exists(dataFilePath)) {
    stop(paste0("dataFilePath: ", dataFilePath, " - NOT FOUND!"))
  }
  tempFileLocation <- tempfile()
  cat(paste0("Unzipping ", dataFilePath))
  utils::unzip(zipfile = dataFilePath, exdir = tempFileLocation)
  on.exit(unlink(tempFileLocation))

  # get list of files in directory and load them into the SQLite database
  dataFiles <- list.files(path = tempFileLocation, pattern = "*.csv")
  if (length(dataFiles) <= 0) {
    stop("Data file does not contain .CSV files to load into the database.")
  }
  databaseFileName <- paste0(tools::file_path_sans_ext(basename(dataFilePath)), ".sqlite")
  databaseFilePath <- file.path(tempFileLocation, databaseFileName)
  connection <- DatabaseConnector::connect(dbms = "sqlite", server = databaseFilePath)

  cat(paste0("Loading database ", databaseFileName))
  for (i in 1:length(dataFiles)) {
    tableData <- readr::read_csv(
      file = file.path(
        tempFileLocation,
        dataFiles[i]
      ), col_types = readr::cols(),
      lazy = FALSE
    )

    tableName <- tools::file_path_sans_ext(toupper(dataFiles[i]))
    cat(paste0(" -- Loading, ", tableName))
    DatabaseConnector::insertTable(connection = connection, tableName = tableName, data = tableData)
  }

  # Move the database to the location where the dataFilePath exists
  file.copy(from = databaseFilePath, to = file.path(
    dirname(dataFilePath),
    databaseFileName
  ), overwrite = TRUE)

  cat("Database load complete")
}
