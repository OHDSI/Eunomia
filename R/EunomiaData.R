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
      rlang::inform(paste0(
        "Consider adding `EUNOMIA_DATA_FOLDER='",
        pathToData,
        "'` to ",
        path.expand("~/.Renviron"),
        " and restarting R."
      ))
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
#' @param from The path to the .ZIP file that contains the csv CDM source files
#' @param to The path to the .sqlite or .duckdb file that will be created
#' @param dbms The file based database system to use: 'sqlite' (default) or 'duckdb'
#' @param verbose Print progress notes? TRUE or FALSE
#' @importFrom tools file_ext
#' @examples
#' \dontrun{
#' extractLoadData("c:/strategusData/GiBleed_5.3.zip")
#' }
#' @seealso
#' \code{\link[Eunomia]{downloadEunomiaData}}
#' @export
extractLoadData <- function(from, to, dbms = "sqlite", verbose = interactive()) {
  stopifnot(dbms == "sqlite" || dbms == "duckdb", is.logical(verbose), length(verbose) == 1)
  stopifnot(is.character(from), length(from) == 1, nchar(from) > 0)
  stopifnot(is.character(to), length(to) == 1, nchar(from) > 0)
  if (tools::file_ext(from) != "zip") stop("Source must be a .zip file")
  if (!file.exists(from)) stop(paste0("zipped csv archive '", from, "' not found!"))

  tempFileLocation <- tempfile()
  if(verbose) cli::cat_line(paste0("Unzipping ", from))
  utils::unzip(zipfile = from, exdir = tempFileLocation)


  # get list of files in directory and load them into the SQLite database
  dataFiles <- sort(list.files(path = tempFileLocation, pattern = "*.csv"))
  if (length(dataFiles) <= 0) {
    stop("Data file does not contain .CSV files to load into the database.")
  }
  databaseFileName <- paste0(tools::file_path_sans_ext(basename(from)), ".", dbms)
  databaseFilePath <- file.path(tempFileLocation, databaseFileName)

  if (dbms == "sqlite") {
    connection <- DBI::dbConnect(RSQLite::SQLite(), dbname = databaseFilePath)
    on.exit(DBI::dbDisconnect(connection), add = TRUE)
  } else if (dbms == "duckdb") {
    connection <- DBI::dbConnect(duckdb::duckdb(), dbdir = databaseFilePath)
    on.exit(DBI::dbDisconnect(connection, shutdown = TRUE), add = TRUE)
  }

  on.exit(unlink(tempFileLocation), add = TRUE)

  if(verbose) {
    cli::cat_rule(paste0("Loading database ", databaseFileName), col = "grey")
  }

  for (i in 1:length(dataFiles)) {
    tableData <- readr::read_csv(
      file = file.path(tempFileLocation, dataFiles[i]),
      col_types = readr::cols(),
      guess_max = 2e6,
      lazy = FALSE
    )
    # CDM table and column names should be lowercase: https://github.com/OHDSI/CommonDataModel/issues/509#issuecomment-1315754238
    names(tableData) <- tolower(names(tableData))
    tableName <- tools::file_path_sans_ext(tolower(dataFiles[i]))
    DBI::dbWriteTable(conn = connection, name = tableName, value = tableData)
    if (verbose) cli::cat_bullet(tableName, bullet = 1)
  }
  file.copy(from = databaseFilePath, to = to, overwrite = TRUE)
  if (verbose) cli::cat_line("Database load complete", col = "grey")
}
