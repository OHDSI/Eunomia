# Copyright 2022 Observational Health Data Sciences and Informatics
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
#' @return
#' A ConnectionDetails object, to be used with the \code{DatabaseConnector} package.
#'
#' @export
getEunomiaConnectionDetails <- function() {
  details <- getConnectionDetails(datasetName = "GiBleed")
  return(details)
}

#' Get Eunomia Connection Details
#'
#' @description
#' Creates a copy of the default (GiBleed) Eunomia database, and provides details for connecting to
#' that copy. Function provides backwards compatibility to prior releases of Eunomia default (GiBleed)
#' dataset
#'
#' @param datasetName    The data set name as found on https://github.com/OHDSI/EunomiaDatasets. The
#'                       data set name corresponds to the folder with the data set ZIP files
#' @param cdmVersion     The OMOP CDM version. This version will appear in the suffix of the data file,
#'                       for example: <datasetName>_<cdmVersion>.zip. Default: '5.3'
#' @param pathToData     The path where the Eunomia data is stored on the file system., By default the
#'                       value of the environment variable "EUNOMIA_DATA_FOLDER" is used.
#' @param dbms           The database system to use. Currently only "sqlite" is supported by getConnectionDetails.
#' @param databaseFile   The path where the database file will be copied to. By default, the database
#'                       will be copied to a temporary folder, and will be deleted at the end of the R
#'                       session.
#'
#' @return
#' A ConnectionDetails object, to be used with the \code{DatabaseConnector} package.
#'
#' @export
getConnectionDetails <- function(datasetName,
                                 cdmVersion = "5.3",
                                 pathToData = Sys.getenv("EUNOMIA_DATA_FOLDER"),
                                 dbms = "sqlite",
                                 databaseFile = tempfile(fileext = paste0(".", dbms))) {

  if(dbms != "sqlite") stop("Only `dbms = 'sqlite'` is supported by getConnectionDetails()")

  datasetLocation <- eunomiaDir(datasetName = datasetName,
                                cdmVersion = cdmVersion,
                                pathToData = pathToData,
                                dbms = dbms,
                                databaseFile = databaseFile)

  details <- DatabaseConnector::createConnectionDetails(dbms = dbms, server = datasetLocation)
  return(details)
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
#'
#' @return The file path to the new Eunomia dataset copy
#' @export
#'
#' @examples
#' \dontrun{
#'  conn <- DBI::dbConnect(RSQLite::SQLite(), eunomiaDir("GiBleed"))
#'  DBI::dbDisconnect(conn)
#'
#'  conn <- DBI::dbConnect(duckdb::duckdb(), eunomiaDir("GiBleed", dbms = "duckdb"))
#'  DBI::dbDisconnect(conn, shutdown = TRUE)
#'
#'  conn <- DatabaseConnector::connect(dbms = "sqlite", server = eunomiaDir("GiBleed"))
#'  DatabaseConnector::disconnect(conn)
#' }
#'
eunomiaDir <- function(datasetName,
                       cdmVersion = "5.3",
                       pathToData = Sys.getenv("EUNOMIA_DATA_FOLDER"),
                       dbms = "sqlite",
                       databaseFile = tempfile(fileext = paste0(".", dbms))) {

  if (is.null(pathToData) || is.na(pathToData) || pathToData == "") {
    stop("The pathToData argument must be specified. Consider setting the EUNOMIA_DATA_FOLDER environment variable, for example in the .Renviron file.")
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

  # zip archive of csv source files
  archiveName <- paste0(datasetName, "_", cdmVersion, ".zip")
  archiveLocation <- file.path(pathToData, archiveName)
  archiveAvailable <- file.exists(archiveLocation)

  if (!datasetAvailable & !archiveAvailable) {
    writeLines(paste("attempting to download", datasetName))
    downloadEunomiaData(datasetName = datasetName, cdmVersion = cdmVersion)
    archiveAvailable <- TRUE
  }

  if (!datasetAvailable & archiveAvailable) {
    writeLines(paste("attempting to extract and load", archiveLocation))
    extractLoadData(from = archiveLocation, to = datasetLocation, dbms = dbms)
    datasetAvailable <- TRUE
  }

  rc <- file.copy(from = datasetLocation, to = databaseFile)
  if (isFALSE(rc)) stop(paste("File copy from", databaseLocation, "to", databaseFile, "failed!"))
  return(databaseFile)
}
