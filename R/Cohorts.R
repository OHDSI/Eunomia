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

#' Construct cohorts
#'
#' @description
#' Creates a set of predefined cohorts in a cohort table. WARNING: this will delete all existing
#' cohorts in the table!
#'
#' @param connectionDetails      The connection details to connect to the (Eunomia) database.
#' @param cdmDatabaseSchema      Deprecated. The cdm must be created in the main schema.
#' @param cohortDatabaseSchema   Deprecated. The cohort table will be created in the main schema.
#' @param cohortTable            Deprecated. Cohort table will be named "cohort".
#'
#' @return
#' A data frame listing all created cohorts.
#'
#' @export
createCohorts <- function(connectionDetails,
                          cdmDatabaseSchema = "main",
                          cohortDatabaseSchema = "main",
                          cohortTable = "cohort") {

  if (!("ConnectionDetails" %in% class(connectionDetails))) {
    stop("connectionDetails is not valid.")
  }

  if (connectionDetails$dbms != "sqlite") {
    stop("createCohorts only supports sqlite")
  }

  if (cdmDatabaseSchema != "main" || cohortDatabaseSchema != "main") {
    stop("sqlite only supports the main schema")
  }

  if (cohortTable != "cohort") {
    warning("The cohortTable argument to createCohorts was deprecated in Eunomia v2.1.0")
  }

  connection <- DBI::dbConnect(RSQLite::SQLite(), connectionDetails$server())
  on.exit(DBI::dbDisconnect(connection))

  # Create example cohort table
  pathToSql <- system.file("sql", "CreateCohortTable.sql",package = "Eunomia", mustWork = TRUE)
  sql <- readChar(pathToSql, file.info(pathToSql)$size)
  sql <- gsub("--[a-zA-Z0-9 ]*", "", sql) # remove comments in sql
  sql <- strsplit(gsub("\n", " ", sql), ";")[[1]] # remove newlines, split on semicolon
  sql <- trimws(sql) # trim white space
  sql <- sql[-which(sql == "")] # remove empty lines

  for (i in seq_along(sql)) {
    DBI::dbExecute(connection, sql[i])
  }

  # Fetch cohort counts:
  sql <- "SELECT cohort_definition_id, COUNT(*) AS count
          FROM main.cohort
          GROUP BY cohort_definition_id"
  counts <- DBI::dbGetQuery(connection, sql)

  cohortsToCreate <- read.csv(system.file("settings", "CohortsToCreate.csv", package = "Eunomia", mustWork = T))
  counts <- merge(cohortsToCreate, counts, by.x = "cohortId", by.y = "cohort_definition_id")
  writeLines("Cohorts created in table main.cohort")
  return(counts)
}
