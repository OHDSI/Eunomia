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


#' Extract the Eunomia database to CSV files
#'
#' @param outputFolder        A folder where the CSV files will be written.
#' @param connectionDetails   Connection details for the Eunomia database. Defaults to a fresh Eunomia
#'                            database.
#'
#'
#' @examples
#' \dontrun{
#' exportToCsv("c:/temp/csv")
#' }
#'
#' @export
exportToCsv <- function(outputFolder = file.path(getwd(), "csv"),
                        connectionDetails = getEunomiaConnectionDetails()) {
  if (!file.exists(outputFolder)) {
    dir.create(outputFolder, recursive = TRUE)
  }
  conn <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  tables <- DatabaseConnector::getTableNames(conn, "main")
  saveCsv <- function(table) {
    fileName <- file.path(outputFolder, sprintf("%s.csv", table))
    writeLines(sprintf("Saving table %s to file %s", table, fileName))
    data <- renderTranslateQuerySql(conn, "SELECT * FROM @table;", table = table)
    write.csv(data, fileName, row.names = FALSE, na = "")
    return(NULL)
  }
  lapply(tables, saveCsv)
  writeLines(sprintf("Done writing CSV files to %s.", outputFolder))
  invisible(NULL)
}
