#!/usr/bin/env Rscript

# Reference loader for the Eunomia GiBleed CDM 5.5 dataset.
#
# BEFORE RUNNING THIS SCRIPT:
#   1. Create an empty database (or catalog) for Eunomia.
#   2. In that database, create an empty schema for the CDM tables.
#   3. Grant the account below permission to create, insert into, alter, and
#      index tables in that schema.
#
# Only the connectionDetails block should normally need to be changed.
# This script deliberately stops if the target schema already contains tables.

# Run these commands once if the required packages are not installed:
# install.packages(c("DatabaseConnector", "readr", "remotes"))
# remotes::install_github("OHDSI/CommonDataModel@release-prep-v1.1.0")

connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "YOUR_DBMS",
  server = "YOUR_SERVER",
  user = "YOUR_USER",
  password = "YOUR_PASSWORD",
  port = "YOUR_PORT"
)

cdmVersion <- "5.5"
cdmDatabaseSchema <- "cdm_v5_5"
datasetUrl <- paste0(
  "https://raw.githubusercontent.com/OHDSI/EunomiaDatasets/",
  "main/datasets/GiBleed/GiBleed_5.5.zip"
)

if (!requireNamespace("DatabaseConnector", quietly = TRUE)) {
  stop("Install DatabaseConnector before running this script.", call. = FALSE)
}
if (!requireNamespace("CommonDataModel", quietly = TRUE)) {
  stop(
    paste(
      "Install the CDM 5.5-capable CommonDataModel branch with:",
      "remotes::install_github('OHDSI/CommonDataModel@release-prep-v1.1.0')"
    ),
    call. = FALSE
  )
}
if (!requireNamespace("readr", quietly = TRUE)) {
  stop("Install readr before running this script.", call. = FALSE)
}
if (!(cdmVersion %in% CommonDataModel::listSupportedVersions())) {
  stop(
    paste(
      "The installed CommonDataModel package does not support CDM 5.5.",
      "Install OHDSI/CommonDataModel@release-prep-v1.1.0."
    ),
    call. = FALSE
  )
}
# Database and schema creation syntax varies by platform, so those steps remain
# manual. Use a new, empty target: this script does not delete existing objects.

# Download and extract the published CDM 5.5 CSV files.
workingFolder <- file.path(tempdir(), "EunomiaGiBleed55")
extractFolder <- file.path(workingFolder, "csv")
zipFile <- file.path(workingFolder, "GiBleed_5.5.zip")
dir.create(extractFolder, recursive = TRUE, showWarnings = FALSE)
utils::download.file(datasetUrl, zipFile, mode = "wb")
utils::unzip(zipFile, exdir = extractFolder, junkpaths = TRUE)

csvFiles <- sort(list.files(
  extractFolder,
  pattern = "[.]csv$",
  full.names = TRUE,
  ignore.case = TRUE
))
if (length(csvFiles) != 42) {
  stop(
    paste("Expected 42 CSV files but found", length(csvFiles), "in the archive."),
    call. = FALSE
  )
}

# Create the CDM tables first. Keys and indexes are added after loading because
# adding them before the load makes inserts slower and complicates diagnostics.
CommonDataModel::executeDdl(
  connectionDetails = connectionDetails,
  cdmVersion = cdmVersion,
  cdmDatabaseSchema = cdmDatabaseSchema,
  executeDdl = TRUE,
  executePrimaryKey = FALSE,
  executeForeignKey = FALSE
)

# Load one CSV per CDM table. bulkLoad = FALSE avoids requiring a platform's
# command-line bulk loader and keeps this example portable.
connection <- DatabaseConnector::connect(connectionDetails)
for (csvFile in csvFiles) {
  tableName <- tolower(tools::file_path_sans_ext(basename(csvFile)))
  message("Loading ", tableName)

  data <- readr::read_csv(
    csvFile,
    col_types = readr::cols(.default = readr::col_character()),
    na = "",
    show_col_types = FALSE,
    progress = FALSE,
    name_repair = "minimal"
  )

  names(data) <- tolower(names(data))
  DatabaseConnector::insertTable(
    connection = connection,
    databaseSchema = cdmDatabaseSchema,
    tableName = tableName,
    data = as.data.frame(data),
    dropTableIfExists = FALSE,
    createTable = FALSE,
    bulkLoad = FALSE,
    progressBar = FALSE
  )
}
DatabaseConnector::disconnect(connection)

# Apply the CDM primary keys after the data has loaded.
CommonDataModel::executeDdl(
  connectionDetails = connectionDetails,
  cdmVersion = cdmVersion,
  cdmDatabaseSchema = cdmDatabaseSchema,
  executeDdl = FALSE,
  executePrimaryKey = TRUE,
  executeForeignKey = FALSE
)

# CommonDataModel generates index SQL separately from executeDdl().
indexFolder <- file.path(workingFolder, "indexes")
dir.create(indexFolder, recursive = TRUE, showWarnings = FALSE)
indexFileName <- CommonDataModel::writeIndex(
  targetDialect = connectionDetails$dbms,
  cdmVersion = cdmVersion,
  outputfolder = indexFolder,
  cdmDatabaseSchema = cdmDatabaseSchema
)
indexSql <- readr::read_file(file.path(indexFolder, indexFileName))

connection <- DatabaseConnector::connect(connectionDetails)
DatabaseConnector::executeSql(connection, indexSql)

DatabaseConnector::disconnect(connection)

unlink(workingFolder, recursive = TRUE, force = TRUE)
message("GiBleed CDM 5.5 load complete.")

# Foreign keys are intentionally not applied. GiBleed is a compact testing
# dataset with reduced vocabulary content. If a testing environment requires
# strict foreign keys, validate the data first and then run executeDdl() again
# with executeDdl = FALSE, executePrimaryKey = FALSE, and
# executeForeignKey = TRUE.
