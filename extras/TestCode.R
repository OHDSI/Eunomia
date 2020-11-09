# Some random code for testing Eunomia with various OHDSI tools

connectionDetails <- Eunomia::getEunomiaConnectionDetails("c:/temp/cdm.sqlite")
cdmDatabaseSchema <- "main"
cohortDatabaseSchema <- "main"
oracleTempSchema <- NULL
cohortTable <- "my_cohort"

# FeatureExtraction -------------------------------
conn <- DatabaseConnector::connect(connectionDetails)

### Populate cohort table ###
sql <- "IF OBJECT_ID('@cohort_database_schema.@cohort_table', 'U') IS NOT NULL
DROP TABLE @cohort_database_schema.@cohort_table;
SELECT 1 AS cohort_definition_id,
  person_id AS subject_id,
  drug_era_start_date AS cohort_start_date,
  drug_era_end_date AS cohort_end_date,
  ROW_NUMBER() OVER (ORDER BY person_id, drug_era_start_date) AS row_id
INTO @cohort_database_schema.@cohort_table FROM @cdm_database_schema.drug_era
WHERE drug_concept_id = 1118084;"
DatabaseConnector::renderTranslateExecuteSql(connection = conn,
                                             sql = sql,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             cohort_database_schema = cohortDatabaseSchema,
                                             cohort_table = cohortTable)

sql <- "SELECT COUNT(*) FROM @cohort_database_schema.@cohort_table WHERE cohort_definition_id = 1"
DatabaseConnector::renderTranslateQuerySql(connection = conn,
                                           sql = sql,
                                           cohort_database_schema = cohortDatabaseSchema,
                                           cohort_table = cohortTable)
DatabaseConnector::disconnect(conn)


settings <- FeatureExtraction::createDefaultCovariateSettings(excludedCovariateConceptIds = 1118084,
                                                              addDescendantsToExclude = TRUE)
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

# Achilles ------------------------------------------- Note: requires development version of
# SqlRender devtools::install_github('ohdsi/SqlRender', ref = 'develop')
library(Achilles)
result <- achilles(connectionDetails,
                   cdmDatabaseSchema = cdmDatabaseSchema,
                   resultsDatabaseSchema = cohortDatabaseSchema,
                   vocabDatabaseSchema = cdmDatabaseSchema,
                   numThreads = 1,
                   sourceName = "Eunomia",
                   cdmVersion = "5.3.0",
                   runHeel = TRUE,
                   runCostAnalysis = FALSE)

# file.copy(connectionDetails$server, 'c:/temp/achilles.sqlite') connectionDetails <-
# DatabaseConnector::createConnectionDetails(server = 'c:/temp/achilles.sqlite', dbms = 'sqlite')

heel <- fetchAchillesHeelResults(connectionDetails, resultsDatabaseSchema = cdmDatabaseSchema)
write.csv(heel, "c:/temp/EunomiaHeel.csv", row.names = FALSE)
head(heel)

exportToJson(connectionDetails,
             cdmDatabaseSchema = cdmDatabaseSchema,
             resultsDatabaseSchema = cdmDatabaseSchema,
             outputPath = "c:/temp/achillesOut")

# Circe cohort definition -----------------------------
conn <- DatabaseConnector::connect(connectionDetails)

### Create cohort table ###
sql <- "IF OBJECT_ID('@cohort_database_schema.@cohort_table', 'U') IS NOT NULL
DROP TABLE @cohort_database_schema.@cohort_table;

CREATE TABLE @cohort_database_schema.@cohort_table (
  cohort_definition_id INT,
  subject_id BIGINT,
  cohort_start_date DATE,
  cohort_end_date DATE
);"
sql <- SqlRender::renderSql(sql,
                            cohort_database_schema = cohortDatabaseSchema,
                            cohort_table = cohortTable)$sql
sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
DatabaseConnector::executeSql(conn, sql)

sql <- SqlRender::readSql("extras/ZoledronicAcid.sql")
sql <- SqlRender::renderSql(sql,
                            cdm_database_schema = cdmDatabaseSchema,
                            vocabulary_database_schema = cdmDatabaseSchema,
                            target_database_schema = cohortDatabaseSchema,
                            target_cohort_table = cohortTable,
                            target_cohort_id = 1)$sql
sql <- SqlRender::translateSql(sql, targetDialect = conn@dbms)$sql
DatabaseConnector::executeSql(conn, sql)
disconnect(conn)

# CohortMethod ------------------------------------------------
conn <- DatabaseConnector::connect(connectionDetails)
sql <- SqlRender::loadRenderTranslateSql("coxibVsNonselVsGiBleed.sql",
                                         packageName = "CohortMethod",
                                         dbms = connectionDetails$dbms,
                                         cdmDatabaseSchema = cdmDatabaseSchema,
                                         resultsDatabaseSchema = cohortDatabaseSchema)
DatabaseConnector::executeSql(conn, sql)

# Check number of subjects per cohort:
sql <- "SELECT cohort_definition_id, COUNT(*) AS count FROM @resultsDatabaseSchema.coxibVsNonselVsGiBleed GROUP BY cohort_definition_id"
DatabaseConnector::renderTranslateQuerySql(connection = conn,
                                           sql = sql,
                                           resultsDatabaseSchema = cohortDatabaseSchema)

DatabaseConnector::disconnect(conn)

nsaids <- c(1118084, 1124300)

library(CohortMethod)
covSettings <- createDefaultCovariateSettings(excludedCovariateConceptIds = nsaids,
                                              addDescendantsToExclude = TRUE)

# Load data:
cohortMethodData <- getDbCohortMethodData(connectionDetails = connectionDetails,
                                          cdmDatabaseSchema = cdmDatabaseSchema,
                                          oracleTempSchema = NULL,
                                          targetId = 1,
                                          comparatorId = 2,
                                          outcomeIds = 3,
                                          exposureDatabaseSchema = cohortDatabaseSchema,
                                          exposureTable = "coxibVsNonselVsGiBleed",
                                          outcomeDatabaseSchema = cohortDatabaseSchema,
                                          outcomeTable = "coxibVsNonselVsGiBleed",
                                          excludeDrugsFromCovariates = FALSE,
                                          firstExposureOnly = TRUE,
                                          removeDuplicateSubjects = "remove all",
                                          washoutPeriod = 180,
                                          covariateSettings = covSettings)
summary(cohortMethodData)
studyPop <- createStudyPopulation(cohortMethodData = cohortMethodData,
                                  outcomeId = 3,
                                  firstExposureOnly = FALSE,
                                  washoutPeriod = 0,
                                  removeDuplicateSubjects = FALSE,
                                  removeSubjectsWithPriorOutcome = TRUE,
                                  minDaysAtRisk = 1,
                                  riskWindowStart = 0,
                                  addExposureDaysToStart = FALSE,
                                  riskWindowEnd = 99999,
                                  addExposureDaysToEnd = TRUE)

ps <- createPs(cohortMethodData = cohortMethodData,
               population = studyPop,
               prior = createPrior("laplace", exclude = c(0), useCrossValidation = TRUE),
               control = createControl(cvType = "auto",
                                       startingVariance = 0.01,
                                       noiseLevel = "quiet",
                                       tolerance = 2e-07,
                                       cvRepetitions = 1,
                                       threads = 10))

plotPs(ps)

model <- getPsModel(ps, cohortMethodData)

matchedPop <- matchOnPs(ps, maxRatio = 1)

plotPs(matchedPop, ps)

strataPop <- stratifyByPs(ps)


balance <- computeCovariateBalance(matchedPop, cohortMethodData)
balance <- computeCovariateBalance(strataPop, cohortMethodData)

table1 <- createCmTable1(balance)
print(table1, row.names = FALSE, right = FALSE)
plotCovariateBalanceScatterPlot(balance, showCovariateCountLabel = TRUE, showMaxLabel = TRUE)

outcomeModel <- fitOutcomeModel(population = studyPop, modelType = "cox", stratified = FALSE)
outcomeModel


outcomeModel <- fitOutcomeModel(population = matchedPop, modelType = "cox")

outcomeModel


# Patient-level prediction -------------------------------------------------

detach("package:CohortMethod", unload = TRUE)
library(PatientLevelPrediction)

connection <- connect(connectionDetails)


### Create cohort table ###
sql <- "IF OBJECT_ID('@cohort_database_schema.@cohort_table', 'U') IS NOT NULL
DROP TABLE @cohort_database_schema.@cohort_table;

CREATE TABLE @cohort_database_schema.@cohort_table (
  cohort_definition_id INT,
  subject_id BIGINT,
  cohort_start_date DATE,
  cohort_end_date DATE
);"
renderTranslateExecuteSql(connection = connection,
                          sql = sql,
                          cohort_database_schema = cohortDatabaseSchema,
                          cohort_table = cohortTable)

# Target: NSAID new use
sql <- "
INSERT INTO @cohort_database_schema.@cohort_table (cohort_definition_id,
                                                   subject_id,
                                                   cohort_start_date,
                                                   cohort_end_date)
SELECT 1 AS cohort_definition_id,
  person_id AS subject_id,
  MIN(drug_exposure_start_date) AS cohort_start_date,
  MIN(drug_exposure_end_date) AS cohort_end_date
FROM @cdm_database_schema.drug_exposure
INNER JOIN @cdm_database_schema.concept_ancestor
  ON drug_concept_id = descendant_concept_id
WHERE ancestor_concept_id IN (1118084, 1124300) -- NSAIDS
GROUP BY person_id;"
renderTranslateExecuteSql(connection = connection,
                          sql = sql,
                          cdm_database_schema = cdmDatabaseSchema,
                          cohort_database_schema = cohortDatabaseSchema,
                          cohort_table = cohortTable)

# Outcome: GI Bleed
sql <- "
INSERT INTO @cohort_database_schema.@cohort_table (cohort_definition_id,
                                                   subject_id,
                                                   cohort_start_date,
                                                   cohort_end_date)
SELECT 2 AS cohort_definition_id,
  person_id AS subject_id,
  MIN(condition_start_date) AS cohort_start_date,
  MIN(condition_end_date) AS cohort_end_date
FROM @cdm_database_schema.condition_occurrence
INNER JOIN @cdm_database_schema.concept_ancestor
  ON condition_concept_id = descendant_concept_id
WHERE ancestor_concept_id = 192671 -- Gastrointestinal haemorrhage
GROUP BY person_id;"
renderTranslateExecuteSql(connection = connection,
                          sql = sql,
                          cdm_database_schema = cdmDatabaseSchema,
                          cohort_database_schema = cohortDatabaseSchema,
                          cohort_table = cohortTable)

sql <- "SELECT cohort_definition_id, COUNT(*) AS count FROM @cohort_database_schema.@cohort_table GROUP BY cohort_definition_id"
renderTranslateQuerySql(connection,
                        sql,
                        cohort_database_schema = cohortDatabaseSchema,
                        cohort_table = cohortTable)



DatabaseConnector::disconnect(connection)

covSettings <- createCovariateSettings(useDemographicsGender = TRUE,
                                       useDemographicsAge = TRUE,
                                       useConditionGroupEraLongTerm = TRUE,
                                       useConditionGroupEraAnyTimePrior = TRUE,
                                       useDrugGroupEraLongTerm = TRUE,
                                       useDrugGroupEraAnyTimePrior = TRUE,
                                       useVisitConceptCountLongTerm = TRUE,
                                       longTermStartDays = -365,
                                       endDays = -1)

plpData <- getPlpData(connectionDetails = connectionDetails,
                      cdmDatabaseSchema = cdmDatabaseSchema,
                      oracleTempSchema = oracleTempSchema,
                      cohortDatabaseSchema = cohortDatabaseSchema,
                      cohortTable = cohortTable,
                      cohortId = 1,
                      covariateSettings = covSettings,
                      outcomeDatabaseSchema = cohortDatabaseSchema,
                      outcomeTable = cohortTable,
                      outcomeIds = 2)

summary(plpData)


population <- createStudyPopulation(plpData = plpData,
                                    outcomeId = 2,
                                    washoutPeriod = 364,
                                    firstExposureOnly = FALSE,
                                    removeSubjectsWithPriorOutcome = TRUE,
                                    priorOutcomeLookback = 9999,
                                    riskWindowStart = 1,
                                    riskWindowEnd = 365,
                                    addExposureDaysToStart = FALSE,
                                    addExposureDaysToEnd = FALSE,
                                    minTimeAtRisk = 364,
                                    requireTimeAtRisk = TRUE,
                                    includeAllOutcomes = TRUE,
                                    verbosity = "DEBUG")

lassoModel <- setLassoLogisticRegression(variance = 0.1, seed = 1234)

lassoResults <- runPlp(population = population,
                       plpData = plpData,
                       modelSettings = lassoModel,
                       testSplit = "person",
                       testFraction = 0.25,
                       nfold = 2,
                       splitSeed = 1234)

viewPlp(lassoResults)

# Source codes -------------------------------------------------------------------
library(DatabaseConnector)
conn <- connect(connectionDetails)
renderTranslateQuerySql(conn, "SELECT TOP 10 * FROM condition_occurrence;")


renderTranslateQuerySql(conn, "SELECT * FROM concept WHERE concept_id = 192671;")

disconnect(conn)
