# Copyright 2019 Observational Health Data Sciences and Informatics
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


#' Get Eunomia Connection Details
#'
#' @return
#' A ConnectionDetails object, to be used with the \code{DatabaseConnector} package.
#'
#' @examples
#' connectionDetails <- getEunomiaConnectionDetails()
#' connection <- connect(connectionDetails)
#' querySql(connection, "SELECT COUNT(*) FROM person;")
#' disconnect(connection)
#'
#' @export
getEunomiaConnectionDetails <- function() {
  return(DatabaseConnector::createConnectionDetails(dbms = "sqlite",
                                                    server = system.file("sqlLite" ,"cdm", package = "Eunomia")))
}
