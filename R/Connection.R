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
#' @param dbms           The DBMS to create a connection details object to support.  Default is sqlite.
#' @param autoDownload   Controls if the CDM zip archive is automatically downloaded if the data is not
#'                       currently available.
#'
#' @return
#' A ConnectionDetails object, to be used with the \code{DatabaseConnector} package.
#'
#' @export
getConnectionDetails <- function(datasetName,
                                 cdmVersion = "5.3",
                                 pathToData = Sys.getenv("EUNOMIA_DATA_FOLDER"),

  dbms = "sqlite", autoDownload = TRUE) {

  if (is.null(pathToData) || is.na(pathToData) || pathToData == "") {
    stop("The pathToData argument must be specified. Consider setting the EUNOMIA_DATA_FOLDER environment variable, for example in the .Renviron file.")
  }

  datasetFileName <- paste0(datasetName, "_", cdmVersion, ".sqlite")
  datasetLocation <- file.path(pathToData, datasetFileName)
  datasetAvailable <- file.exists(datasetLocation)

  archiveName <- paste0(datasetName, "_", cdmVersion, ".zip")
  archiveLocation <- file.path(pathToData, archiveName)
  archiveAvailable <- file.exists(archiveLocation)

  if (!datasetAvailable & !archiveAvailable) {
    writeLines(paste("attempting to download", datasetName))
    Eunomia::downloadEunomiaData(datasetName = datasetName, cdmVersion = cdmVersion)
    archiveAvailable <- T
  }

  if (!datasetAvailable & archiveAvailable) {
    writeLines(paste("attempting to extract and load", archiveLocation))
    Eunomia::extractLoadData(dataFilePath = archiveLocation)
    datasetAvailable <- T
  }

  details <- DatabaseConnector::createConnectionDetails(dbms = "sqlite", server = datasetLocation)
  return(details)
}
