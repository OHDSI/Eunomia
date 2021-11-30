# Copyright 2021 Observational Health Data Sciences and Informatics
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
#' @param cdmDatabaseSchema      The name of the database schema holding the CDM data.
#' @param cohortDatabaseSchema   The name of the database schema where the cohorts will be written.
#' @param cohortTable            The name of the table in the cohortDatabaseSchema where the cohorts
#'                               will be written.
#'
#' @return
#' A data frame listing all created cohorts.
#'
#' @export
createCohorts <- function(connectionDetails,
                          cdmDatabaseSchema = "main",
                          cohortDatabaseSchema = "main",
                          cohortTable = "cohort") {
  if (Eunomia::supportsJava8()) {
    connection <- DatabaseConnector::connect(connectionDetails)
    on.exit(DatabaseConnector::disconnect(connection))

    # Create study cohort table structure:
    sql <-
      SqlRender::loadRenderTranslateSql(
        sqlFilename = "CreateCohortTable.sql",
        packageName = "Eunomia",
        dbms = connectionDetails$dbms,
        cohort_database_schema = cohortDatabaseSchema,
        cohort_table = cohortTable
      )
    DatabaseConnector::executeSql(connection,
                                  sql,
                                  progressBar = FALSE,
                                  reportOverallTime = FALSE)

    # Instantiate cohorts:
    pathToCsv <-
      system.file("settings", "CohortsToCreate.csv", package = "Eunomia")
    cohortsToCreate <- read.csv(pathToCsv)
    for (i in 1:nrow(cohortsToCreate)) {
      writeLines(paste("Creating cohort:", cohortsToCreate$name[i]))
      sql <-
        SqlRender::loadRenderTranslateSql(
          sqlFilename = paste0(cohortsToCreate$name[i], ".sql"),
          packageName = "Eunomia",
          dbms = connectionDetails$dbms,
          cdm_database_schema = cdmDatabaseSchema,
          cohort_database_schema = cohortDatabaseSchema,
          cohort_table = cohortTable,
          cohort_definition_id = cohortsToCreate$cohortId[i]
        )
      DatabaseConnector::executeSql(connection, sql)
    }

    # Fetch cohort counts:
    sql <-
      "SELECT cohort_definition_id, COUNT(*) AS count FROM @cohort_database_schema.@cohort_table GROUP BY cohort_definition_id"
    counts <- DatabaseConnector::renderTranslateQuerySql(
      connection,
      sql,
      cohort_database_schema = cohortDatabaseSchema,
      cohort_table = cohortTable,
      snakeCaseToCamelCase = TRUE
    )
    counts <-
      merge(cohortsToCreate, counts, by.x = "cohortId", by.y = "cohortDefinitionId")
    writeLines(sprintf(
      "Cohorts created in table %s.%s",
      cohortDatabaseSchema,
      cohortTable
    ))
    return(counts)
  }
}
