#' Download Eunomia data files
#'
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
#' @param verbose       Provide additional logging details during execution.
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
                                overwrite = FALSE,
                                verbose = FALSE) {
  if (is.null(pathToData) || is.na(pathToData) || pathToData == "") {
    pathToData <- tempdir()
    warningContent <- paste("The pathToData argument was not specified and the EUNOMIA_DATA_FOLDER environment variable was not set. Using", pathToData)
    rlang::warn(warningContent, .frequency = c("once"), .frequency_id = "data_folder")
  }

  if (is.null(datasetName) || is.na(datasetName) || datasetName == "") {
    stop("The datasetName argument must be specified.")
  }

  if (!dir.exists(pathToData)) {
    dir.create(pathToData, recursive = TRUE)
  }

  datasetNameVersion <- paste0(datasetName, "_", cdmVersion)
  zipName <- paste0(datasetNameVersion, ".zip")

  if (file.exists(file.path(pathToData, zipName)) && !overwrite) {
    message("Dataset already exists (",file.path(pathToData, zipName),"). Specify overwrite=T to overwrite existing zip archive.", appendLF = TRUE)
  } else {
    # downloads the file from github or user specified location
    baseUrl <- Sys.getenv("EUNOMIA_DATASETS_URL")
    if (baseUrl == "") {
      baseUrl <- "https://raw.githubusercontent.com/OHDSI/EunomiaDatasets/main/datasets"
    }
    result <- utils::download.file(
      url = paste(baseUrl, datasetName, zipName, sep = "/"),
      destfile = file.path(
        pathToData,
        zipName
      )
    )

    invisible(file.path(pathToData, zipName))
  }
}

#' Extract the Eunomia data files and load into a database
#' Extract files from a .ZIP file and creates a OMOP CDM database that is then stored in the
#' same directory as the .ZIP file.
#'
#' @param from The path to the .ZIP file that contains the csv CDM source files
#' @param to The path to the .sqlite or .duckdb file that will be created
#' @param dbms The file based database system to use: 'sqlite' (default) or 'duckdb'
#' @param cdmVersion The version of the OMOP CDM that are represented in the archive files.
#' @param inputFormat The format of the files expected in the archive. (csv or parquet)
#' @param verbose Provide additional logging details during execution.
#' @returns No return value, called to load archive into a database file.
#' @importFrom tools file_ext
#' @examples
#' \dontrun{
#' extractLoadData("c:/strategusData/GiBleed_5.3.zip")
#' }
#' @seealso
#' \code{\link[Eunomia]{downloadEunomiaData}}
#' @export
extractLoadData <- function(from, to, dbms = "sqlite",cdmVersion="5.3", inputFormat="csv", verbose = FALSE) {
  stopifnot(dbms == "sqlite" || dbms == "duckdb")
  stopifnot(is.character(from), length(from) == 1, nchar(from) > 0)
  stopifnot(is.character(to), length(to) == 1, nchar(to) > 0)
  if (tools::file_ext(from) != "zip") {
    stop("Source must be a .zip file")
  }
  if (!file.exists(from)) {
    stop(paste0("zipped archive '", from, "' not found!"))
  }

  unzipLocation <- tempdir()
  utils::unzip(zipfile = from, exdir = unzipLocation, junkpaths = TRUE)
  if (verbose) {
    message("unzipping to: ",unzipLocation,appendLF = TRUE)
  }
  loadDataFiles(dataPath = unzipLocation, dbPath = to, dbms = dbms,cdmVersion = cdmVersion, inputFormat=inputFormat, verbose = verbose)

  unlink(unzipLocation)
}

#' Load data files into a database(sqlite or duckdb)
#'
#' Load data from csv or parquet files into a database file (sqlite or duckdb).
#'
#' @param dataPath       The path to the directory containing CDM source files (csv or parquet)
#' @param dbPath         The path to the .sqlite or .duckdb file that will be created
#' @param dbms           The file-based database system to use: 'sqlite' (default) or 'duckdb'
#' @param inputFormat    The input format of the files to load.  Supported formats include csv, parquet.
#' @param cdmVersion     The CDM version to create in the resulting database. Supported versions are 5.3 and 5.4
#' @param cdmDatabaseSchema The schema in which to create the CDM tables. Default is main.
#' @param verbose        Provide additional logging details during execution.
#' @param overwrite      Remove and replace an existing data set.
#' @returns No return value, loads data into database file.
#' @export
loadDataFiles <- function(dataPath,
                      dbPath,
                      inputFormat = "csv",
                      cdmVersion="5.3",
                      cdmDatabaseSchema = "main",
                      dbms = "sqlite",
                      verbose = FALSE,
                      overwrite = FALSE) {
  stopifnot(inputFormat %in% c("csv","parquet"))
  stopifnot(dbms == "sqlite" || dbms == "duckdb")
  stopifnot(is.character(dataPath), length(dataPath) == 1, nchar(dataPath) > 0)
  stopifnot(is.character(dbPath), length(dbPath) == 1, nchar(dbPath) > 0)

  dataFiles <- sort(list.files(path = dataPath, pattern = paste("*",inputFormat,sep=".")))
  if (length(dataFiles) <= 0) {
    stop("Data directory does not contain files to load into the database.")
  }

  if (verbose) {
    message("connecting to: ", dbms, appendLF = TRUE)
  }

  if (overwrite) {
    if (file.exists(dbPath)) {
      if (verbose) {
        message("deleting existing file: ", dbPath, appendLF = TRUE)
      }
      unlink(dbPath)
    }
  }

  if (dbms == "sqlite") {
    connection <- DBI::dbConnect(RSQLite::SQLite(), dbname = dbPath)
    on.exit(DBI::dbDisconnect(connection), add = TRUE)
  } else if (dbms == "duckdb") {
    connection <- DBI::dbConnect(duckdb::duckdb(), dbdir = dbPath)
    on.exit(DBI::dbDisconnect(connection, shutdown = TRUE), add = TRUE)
    on.exit(duckdb::duckdb_shutdown(duckdb::duckdb()), add=TRUE)
  }

  # creating tables via DDL eliminates issues with inferring column types
  # avoiding use of executeDdl as it requires DatabaseConnector which has some
  # issues with managing tables in Sqlite & DuckDb

  tempDdlFolder <- tempdir()
  # when running multiple tests in one session, R returns the same tempdir
  # if multiple databases are being tested, we need to remove existing ddl
  # if you unlink the entire tempdir, you can get rid of the database file created before completing tests
  existingDdlFiles <- sort(list.files(path = tempDdlFolder, full.names = TRUE, pattern = ".*\\.sql$"))
  for (existingDdlFile in existingDdlFiles) {
    unlink(existingDdlFile)
  }

  CommonDataModel::writeDdl(
    targetDialect = dbms,
    cdmVersion = cdmVersion,
    cdmDatabaseSchema = cdmDatabaseSchema,
    outputfolder = tempDdlFolder
  )

  ddlFiles <- sort(list.files(path = tempDdlFolder, full.names = TRUE, pattern = ".*\\.sql$"))

  for (ddlFile in ddlFiles) {
    if (verbose) {
      message("executing ddl statements from: ", ddlFile, appendLF = TRUE)
    }

    ddlFileContents <- readChar(ddlFile, file.info(ddlFile)$size)
    statements <- as.list(strsplit(ddlFileContents, ';')[[1]])
    for (statement in statements) {
      DBI::dbExecute(
        conn = connection,
        statement = statement
      )
    }
  }

  for (i in 1:length(dataFiles)) {
    dataFile <- dataFiles[i]
    if (verbose) {
      dataFileMessage <- paste("loading file: ", dataFile)
      message(dataFileMessage, appendLF = TRUE)
    }

    if (inputFormat == "csv") {
      tableData <- readr::read_csv(
        file = file.path(dataPath, dataFiles[i]),
        show_col_types = FALSE
      )
    } else if (inputFormat == "parquet") {
      tableData <- arrow::read_parquet(
        file = file.path(dataPath, dataFiles[i])
      )
    }

    names(tableData) <- tolower(names(tableData))
    tableName <- tools::file_path_sans_ext(tolower(dataFiles[i]))

    if (dbms == "sqlite") {
      for (j in seq_len(ncol(tableData))) {
        column <- tableData[[j]]
        if (inherits(column, "Date")) {
          tableData[, j] <- as.numeric(as.POSIXct(as.character(column), origin = "1970-01-01", tz = "GMT"))
        }
        if (inherits(column, "POSIXct")) {
          tableData[, j] <- as.numeric(as.POSIXct(column, origin = "1970-01-01", tz = "GMT"))
        }
      }
    }

    if (verbose) {
      message("saving table: ",tableName," (rows: ", nrow(tableData), ")",appendLF = TRUE)
    }

    DBI::dbWriteTable(conn = connection, name = tableName, value = tableData, append=TRUE)
  }
}

#' Export data files from a database(sqlite or duckdb)
#'
#' Helper function to export data to csv or parquet files from a database file (sqlite or duckdb).
#'
#' @param dbPath         The path to the source .sqlite or .duckdb file
#' @param outputFolder       The path to the export destination directory
#' @param dbms           The file-based database system to use: 'sqlite' (default) or 'duckdb'
#' @param outputFormat    The output format for the files.  Supported formats include csv, parquet.
#' @param verbose       Boolean argument controlling verbose debugging output
#' @returns No return value, called to export to outputFolder.
#' @export
exportDataFiles <- function(dbPath, outputFolder, outputFormat="csv", dbms = "sqlite", verbose=FALSE) {
  stopifnot(outputFormat %in% c("csv","parquet"))
  stopifnot(dbms %in% c("sqlite", "duckdb"))

  if (dbms == "sqlite") {
    connection <- DBI::dbConnect(RSQLite::SQLite(), dbname = dbPath)
    on.exit(DBI::dbDisconnect(connection), add = TRUE)
  } else if (dbms == "duckdb") {
    connection <- DBI::dbConnect(duckdb::duckdb(), dbdir = dbPath)
    on.exit(DBI::dbDisconnect(connection, shutdown = TRUE), add = TRUE)
    on.exit(duckdb::duckdb_shutdown(duckdb::duckdb()),add=TRUE)
  }

  tableNames <- DBI::dbListTables(connection)
  message("processing ", length(tableNames), " tables", appendLF = TRUE)

  if (!dir.exists(outputFolder)) {
    dir.create(
      path = outputFolder,
      recursive = T
    )
  }

  for (tableName in tableNames) {
    if (verbose) {
      message("processing ", tableName, appendLF = TRUE)
    }

    outputFileName <- file.path(outputFolder,tableName)

    if (outputFormat == "csv") {
      filePath <- paste(outputFileName, "csv", sep = ".")
      query <- paste("SELECT * FROM", tableName)
      result <- DBI::dbSendQuery(connection, query)
      data <- DBI::dbFetch(result)
      DBI::dbClearResult(result)
      write.csv(data, filePath, row.names = T)
    } else if (outputFormat == "parquet") {
      filePath <- paste(outputFileName, "parquet", sep = ".")
      query <- paste0("copy ", tableName, " to '", filePath, "' (FORMAT PARQUET);")
      DBI::dbExecute(connection,query)
    } else {
      message("unknown file format")
    }
  }
}
