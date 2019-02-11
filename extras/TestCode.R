options(fftempdir = "s:/fftemp")

connectionDetails <- Eunomia::getEunomiaConnectionDetails()
cdmDatabaseSchema <- "main"
cohortDatabaseSchema <- "main"
oracleTempSchema <- NULL
cohortTable <- "my_cohort"

# FeatureExtraction -------------------------------
conn <- DatabaseConnector::connect(connectionDetails)

### Populate cohort table ###
sql <- "IF OBJECT_ID('@cohort_database_schema.@cohort_table', 'U') IS NOT NULL
DROP TABLE @cohort_database_schema.@cohort_table;
SELECT 1 AS cohort_definition_id, person_id AS subject_id, drug_era_start_date AS cohort_start_date, drug_era_end_date AS cohort_end_date, ROW_NUMBER() OVER (ORDER BY person_id, drug_era_start_date) AS row_id
INTO @cohort_database_schema.@cohort_table FROM @cdm_database_schema.drug_era
WHERE drug_concept_id = 1118084;"
sql <- SqlRender::renderSql(sql,
                            cdm_database_schema = cdmDatabaseSchema,
                            cohort_database_schema = cohortDatabaseSchema,
                            cohort_table = cohortTable)$sql
sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
DatabaseConnector::executeSql(conn, sql)

sql <- "SELECT COUNT(*) FROM @cohort_database_schema.@cohort_table WHERE cohort_definition_id = 1"
sql <- SqlRender::renderSql(sql,
                            cohort_database_schema = cohortDatabaseSchema,
                            cohort_table = cohortTable)$sql
sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
DatabaseConnector::querySql(conn, sql)
DatabaseConnector::disconnect(conn)


settings <- FeatureExtraction::createDefaultCovariateSettings(excludedCovariateConceptIds = 1118084, addDescendantsToExclude = TRUE)
covs <- FeatureExtraction::getDbCovariateData(connectionDetails = connectionDetails,
                                              oracleTempSchema = oracleTempSchema,
                                              cdmDatabaseSchema = cdmDatabaseSchema,
                                              cohortDatabaseSchema = cohortDatabaseSchema,
                                              cohortTable = cohortTable,
                                              cohortId = 1,
                                              rowIdField = "row_id",
                                              cohortTableIsTemp = FALSE,
                                              covariateSettings = settings,
                                              aggregated = FALSE)
summary(covs)

# Achilles -------------------------------------------

library(Achilles)
achilles(connectionDetails,
         cdmDatabaseSchema = cdmDatabaseSchema,
         resultsDatabaseSchema = cohortDatabaseSchema,
         vocabDatabaseSchema = cdmDatabaseSchema,
         numThreads = 1,
         sourceName = "Eunomia",
         cdmVersion = "5.0.0",
         runHeel = TRUE,
         runCostAnalysis = FALSE)

