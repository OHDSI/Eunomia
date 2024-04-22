# Copyright 2023 Observational Health Data Sciences and Informatics
#
# This file is part of Eunomia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


#' Get Default Eunomia Connection Details
#'
#' @description
#' Creates a copy of the default (GiBleed) Eunomia database, and provides details for connecting to
#' that copy. Function provides backwards compatibility to prior releases of Eunomia default (GiBleed)
#' dataset
#'
#' @param databaseFile The path where the database file will be copied to. By default, the database will
#'                     be copied to a temporary folder, and will be deleted at the end of the R session.
#' @param dbms         The target dialect, by default "sqlite".
#'
#' @return
#' A ConnectionDetails object, to be used with the \code{DatabaseConnector} package.
#'
#' @export
getEunomiaConnectionDetails <- function(databaseFile = tempfile(fileext = ".sqlite"), dbms = "sqlite") {

  if (interactive() & !("DatabaseConnector" %in% rownames(utils::installed.packages()))) {
    message("The DatabaseConnector package is required but not installed.")
    if (!isTRUE(utils::askYesNo("Would you like to install DatabaseConnector?"))) {
      return(invisible(NULL))
    } else {
      utils::install.packages("DatabaseConnector")
    }
  }

  datasetLocation <- getDatabaseFile(datasetName = "GiBleed", dbms = dbms, databaseFile = databaseFile)
  DatabaseConnector::createConnectionDetails(dbms = dbms, server = datasetLocation)
}

#' Create a copy of a Eunomia dataset
#'
#' @description
#' Creates a copy of a Eunomia database, and returns the path to the new database file.
#' If the dataset does not yet exist on the user's computer it will attempt to download the source data
#' to the the path defined by the EUNOMIA_DATA_FOLDER environment variable.
#'
#' @param datasetName    The data set name as found on https://github.com/OHDSI/EunomiaDatasets. The
#'                       data set name corresponds to the folder with the data set ZIP files
#' @param cdmVersion     The OMOP CDM version. This version will appear in the suffix of the data file,
#'                       for example: <datasetName>_<cdmVersion>.zip. Default: '5.3'
#' @param pathToData     The path where the Eunomia data is stored on the file system., By default the
#'                       value of the environment variable "EUNOMIA_DATA_FOLDER" is used.
#' @param dbms           The database system to use. "sqlite" (default) or "duckdb"
#' @param databaseFile   The path where the database file will be copied to. By default, the database
#'                       will be copied to a temporary folder, and will be deleted at the end of the R
#'                       session.
#' @param inputFormat    The format of the files expected in the archive. (csv or parquet)
#' @param verbose        Provide additional logging details during execution
#' @param overwrite      Remove and replace an existing data set.
#'
#' @return The file path to the new Eunomia dataset copy
#' @export
#'
#' @examples
#' \dontrun{
#'  conn <- DBI::dbConnect(RSQLite::SQLite(), getDatabaseFile("GiBleed"))
#'  DBI::dbDisconnect(conn)
#'
#'  conn <- DBI::dbConnect(duckdb::duckdb(), getDatabaseFile("GiBleed", dbms = "duckdb"))
#'  DBI::dbDisconnect(conn, shutdown = TRUE)
#'
#'  conn <- DatabaseConnector::connect(dbms = "sqlite", server = getDatabaseFile("GiBleed"))
#'  DatabaseConnector::disconnect(conn)
#' }
#'
getDatabaseFile <- function(datasetName,
                            cdmVersion = "5.3",
                            pathToData = Sys.getenv("EUNOMIA_DATA_FOLDER"),
                            dbms = "sqlite",
                            databaseFile = tempfile(fileext = paste0(".", dbms)),
                            inputFormat = "csv",
                            verbose = FALSE,
                            overwrite = TRUE) {

  if (is.null(pathToData) || is.na(pathToData) || pathToData == "") {
    pathToData <- tempdir()
  }

  stopifnot(is.character(dbms), length(dbms) == 1, dbms %in% c("sqlite", "duckdb"))
  stopifnot(is.character(cdmVersion), length(cdmVersion) == 1, cdmVersion %in% c("5.3", "5.4"))

  if (dbms == "duckdb") {
    rlang::check_installed("duckdb")
    # duckdb database are tied to a specific version of duckdb until it reaches v1.0
    duckdbVersion <- substr(utils::packageVersion("duckdb"), 1, 3)
    datasetFileName <- paste0(datasetName, "_", cdmVersion, "_", duckdbVersion, ".", dbms)
  } else {
    datasetFileName <- paste0(datasetName, "_", cdmVersion, ".", dbms)
  }

  # cached sqlite or duckdb file to be copied
  datasetLocation <- file.path(pathToData, datasetFileName)
  datasetAvailable <- file.exists(datasetLocation)
  if (datasetAvailable && overwrite) {
    if (verbose) {
      message("overwrite specified, deleting existing dataset: ", datasetLocation, appendLF = TRUE)
    }
    unlink(datasetLocation)
    datasetAvailable <- FALSE
  }

  if (verbose) {
    message("dataset: ",datasetLocation, " available: ",datasetAvailable, appendLF = TRUE)
  }

  # zip archive of csv source files
  archiveName <- paste0(datasetName, "_", cdmVersion, ".zip")
  archiveLocation <- file.path(pathToData, archiveName)
  archiveAvailable <- file.exists(archiveLocation)

  if (archiveAvailable && overwrite) {
    if (verbose) {
      message("overwrite specified, deleting existing archive: ", archiveLocation, appendLF = TRUE)
    }
    unlink(archiveLocation)
    archiveAvailable <- FALSE
  }

  if (verbose) {
    message("archive: ",archiveLocation," available:",archiveAvailable,appendLF = TRUE)
  }

  if (!datasetAvailable && !archiveAvailable) {
    message(paste("attempting to download", datasetName))
    downloadedData <- downloadEunomiaData(datasetName = datasetName, cdmVersion = cdmVersion, pathToData = pathToData, verbose=verbose)
    if (verbose) {
      message("downloaded: ",downloadedData,appendLF = TRUE)
    }
    archiveAvailable <- TRUE
  }

  if (!datasetAvailable && archiveAvailable) {
    message("attempting to extract and load: ", archiveLocation," to: ",datasetLocation,appendLF = TRUE)
    extractLoadData(from = archiveLocation, to = datasetLocation, dbms = dbms, cdmVersion = cdmVersion, inputFormat=inputFormat, verbose=verbose)
    datasetAvailable <- TRUE
  }

  if (verbose) {
    message("copying: ",datasetLocation," to: ", databaseFile, appendLF = TRUE)
  }

  copySuccess <- file.copy(from = datasetLocation, to = databaseFile, overwrite = overwrite)
  if (isFALSE(copySuccess)) {
    stop(paste("File copy from", datasetLocation, "to", databaseFile, "failed!"))
  }
  invisible(databaseFile)
}
