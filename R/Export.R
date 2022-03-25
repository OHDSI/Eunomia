# Copyright 2020 Observational Health Data Sciences and Informatics
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
#' \donttest{
#' # For this example we'll create a temp folder:
#' folder <- tempfile()
#' dir.create(folder)
#'
#' exportToCsv(folder)
#'
#' list.files(folder)
#'
#'  #  [1] "CARE_SITE.csv"             "CDM_SOURCE.csv"            "COHORT.csv"
#'  #  [4] "COHORT_ATTRIBUTE.csv"      "CONCEPT.csv"               "CONCEPT_ANCESTOR.csv"
#'  #  [7] "CONCEPT_CLASS.csv"         "CONCEPT_RELATIONSHIP.csv"  "CONCEPT_SYNONYM.csv"
#'  # [10] "CONDITION_ERA.csv"         "CONDITION_OCCURRENCE.csv"  "COST.csv"
#'  # [13] "DEATH.csv"                 "DEVICE_EXPOSURE.csv"       "DOMAIN.csv"
#'  # [16] "DOSE_ERA.csv"              "DRUG_ERA.csv"              "DRUG_EXPOSURE.csv"
#'  # [19] "DRUG_STRENGTH.csv"         "FACT_RELATIONSHIP.csv"     "LOCATION.csv"
#'  # [22] "MEASUREMENT.csv"           "METADATA.csv"              "NOTE.csv"
#'  # [25] "NOTE_NLP.csv"              "OBSERVATION.csv"           "OBSERVATION_PERIOD.csv"
#'  # [28] "PAYER_PLAN_PERIOD.csv"     "PERSON.csv"                "PROCEDURE_OCCURRENCE.csv"
#'  # [31] "PROVIDER.csv"              "RELATIONSHIP.csv"          "SOURCE_TO_CONCEPT_MAP.csv"
#'  # [34] "SPECIMEN.csv"              "VISIT_DETAIL.csv"          "VISIT_OCCURRENCE.csv"
#'  # [37] "VOCABULARY.csv"
#'
#'  # Cleaning up the temp folder used in this example:
#'  unlink(folder, recursive = TRUE)
#'  }
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
    data <- DatabaseConnector::renderTranslateQuerySql(conn, "SELECT * FROM @table;", table = table)
    write_csv(data, fileName, na = "")
    return(NULL)
  }
  lapply(tables, saveCsv)
  writeLines(sprintf("Done writing CSV files to %s.", outputFolder))
  invisible(NULL)
}
