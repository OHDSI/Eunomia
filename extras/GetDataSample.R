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

connectionDetails <- Eunomia::getEunomiaConnectionDetails("c:/temp/cdm.sqlite")
conn <- DatabaseConnector::connect(connectionDetails)
DatabaseConnector::renderTranslateExecuteSql(conn, "DROP TABLE coxibvsnonselvsgibleed;")
DatabaseConnector::executeSql(conn, "VACUUM main;")
DatabaseConnector::disconnect(conn)



# This code is obsolete

library(DatabaseConnector)
library(SqlRender)

remoteConnDetails <- createConnectionDetails(dbms = "pdw",
                                             server = Sys.getenv("PDW_SERVER"),
                                             user = NULL,
                                             password = NULL,
                                             port = Sys.getenv("PDW_PORT"))
cdmDatabaseSchema <- "cdm_synpuf_v667.dbo"

remoteConn <- connect(remoteConnDetails)

sql <- readSql("extras/SamplePersonsAndConcepts.sql")
renderTranslateExecuteSql(connection = remoteConn,
                          sql = sql,
                          cdm_database_schema = cdmDatabaseSchema,
                          person_sample_size = 10000)

tempFileName <- file.path(tempdir(), "cdm.sqlite")
localConn <- connect(dbms = "sqlite", server = tempFileName)

extractTable <- function(tableName,
                         restrictConcepts = TRUE,
                         conceptField = "concept_id",
                         conceptField2 = NULL,
                         restrictPersons = TRUE) {
  ParallelLogger::logInfo("Fetching and storing table ", tableName)
  sql <- "SELECT @table_name.*
  FROM @cdm_database_schema.@table_name
  {@restrict_concepts} ? {
  INNER JOIN #concept_sample concept_sample
  ON concept_sample.concept_id = @table_name.@concept_field
  }
  {@restrict_concepts_2} ? {
  INNER JOIN #concept_sample concept_sample_2
  ON concept_sample_2.concept_id = @table_name.@concept_field_2
  }
  {@restrict_person} ? {
  INNER JOIN #person_sample person_sample
  ON person_sample.person_id = @table_name.person_id
  };"
  table <- renderTranslateQuerySql(connection = remoteConn,
                                   sql = sql,
                                   cdm_database_schema = cdmDatabaseSchema,
                                   table_name = tableName,
                                   restrict_concepts = restrictConcepts,
                                   concept_field = conceptField,
                                   restrict_concepts_2 = !is.null(conceptField2),
                                   concept_field_2 = conceptField2,
                                   restrict_person = restrictPersons)
  insertTable(localConn, tableName, table)
  ParallelLogger::logInfo("- Added ", nrow(table), " rows")
}

extractTable(tableName = "concept",
             restrictConcepts = TRUE,
             conceptField = "concept_id",
             restrictPersons = FALSE)
extractTable(tableName = "concept_ancestor",
             restrictConcepts = TRUE,
             conceptField = "descendant_concept_id",
             conceptField2 = "ancestor_concept_id",
             restrictPersons = FALSE)
extractTable(tableName = "concept_relationship",
             restrictConcepts = TRUE,
             conceptField = "concept_id_1",
             conceptField2 = "concept_id_2",
             restrictPersons = FALSE)
extractTable(tableName = "drug_era",
             restrictConcepts = TRUE,
             conceptField = "drug_concept_id",
             restrictPersons = TRUE)
extractTable(tableName = "drug_exposure",
             restrictConcepts = TRUE,
             conceptField = "drug_concept_id",
             restrictPersons = TRUE)
extractTable(tableName = "device_exposure",
             restrictConcepts = TRUE,
             conceptField = "device_concept_id",
             restrictPersons = TRUE)
extractTable(tableName = "condition_era",
             restrictConcepts = TRUE,
             conceptField = "condition_concept_id",
             restrictPersons = TRUE)
extractTable(tableName = "condition_occurrence",
             restrictConcepts = TRUE,
             conceptField = "condition_concept_id",
             restrictPersons = TRUE)
extractTable(tableName = "procedure_occurrence",
             restrictConcepts = TRUE,
             conceptField = "procedure_concept_id",
             restrictPersons = TRUE)
extractTable(tableName = "measurement",
             restrictConcepts = TRUE,
             conceptField = "measurement_concept_id",
             restrictPersons = TRUE)
extractTable(tableName = "observation",
             restrictConcepts = TRUE,
             conceptField = "observation_concept_id",
             restrictPersons = TRUE)
extractTable(tableName = "person", restrictConcepts = FALSE, restrictPersons = TRUE)
extractTable(tableName = "observation_period", restrictConcepts = FALSE, restrictPersons = TRUE)
extractTable(tableName = "visit_occurrence", restrictConcepts = FALSE, restrictPersons = TRUE)
extractTable(tableName = "cdm_source", restrictConcepts = FALSE, restrictPersons = FALSE)

disconnect(remoteConn)
disconnect(localConn)

if (!file.exists("inst/zip")) {
  dir.create("inst/zip", recursive = TRUE)
}
DatabaseConnector::createZipFile(zipFile = "inst/zip/cdm.zip", files = tempFileName, rootFolder = dirname(tempFileName))
unlink(tempFileName)
