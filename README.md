# Eunomia

[![Build Status](https://github.com/OHDSI/Eunomia/workflows/R-CMD-check/badge.svg)](https://github.com/OHDSI/Eunomia/actions?query=workflow%3AR-CMD-check)
[![codecov.io](https://codecov.io/github/OHDSI/Eunomia/coverage.svg?branch=main)](https://app.codecov.io/github/OHDSI/Eunomia?branch=main)
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/Eunomia)](https://cran.r-project.org/package=Eunomia)
[![CRAN_Status_Badge](http://cranlogs.r-pkg.org/badges/Eunomia)](https://cran.r-project.org/package=Eunomia)

Eunomia is part of [HADES](https://ohdsi.github.io/Hades/).

## Introduction

Eunomia is a standard dataset manager for sample OMOP (Observational Medical Outcomes Partnership) Common Data Model (CDM) datasets. Eunomia facilitates access to sample datasets from the [EunomiaDatasets repository](https://github.com/OHDSI/EunomiaDatasets). Eunomia is used for testing and demonstration purposes, including many of the exercises in [the Book of OHDSI](https://ohdsi.github.io/TheBookOfOhdsi/). For functions that require a schema name, use `main`.

The default dataset is GiBleed in OMOP CDM v5.5 format. Earlier supported CDM versions remain available through the `cdmVersion` argument of `getDatabaseFile()` and `downloadEunomiaData()`.

## Features

- Download sample datasets from the [EunomiaDatasets repository](https://github.com/OHDSI/EunomiaDatasets), including a subset of the Standardized Vocabularies.
- Create local SQLite databases by default, with optional DuckDB support.
- Connect through DBI directly or create connection details for DatabaseConnector-based HADES workflows.
- Run locally without setting up a database server.

## Installation

See the [HADES R setup instructions](https://ohdsi.github.io/Hades/rSetup.html) for general R environment guidance.

Install Eunomia and DatabaseConnector for the primary HADES workflow:

```r
install.packages(c("Eunomia", "DatabaseConnector"))
```

DatabaseConnector is a suggested dependency and is not attached when Eunomia is loaded. To use DuckDB instead of the default SQLite database, also install the `duckdb` package.

## Quick start

```r
library(Eunomia)

connectionDetails <- getEunomiaConnectionDetails()
connection <- DatabaseConnector::connect(connectionDetails)

DatabaseConnector::querySql(
  connection,
  "SELECT COUNT(*) AS person_count FROM main.person;"
)
DatabaseConnector::getTableNames(connection, databaseSchema = "main")

DatabaseConnector::disconnect(connection)
```

## Downloading datasets

`downloadEunomiaData()` downloads the raw ZIP archive for a dataset. It does not create a database:

```r
dataFolder <- file.path(tempdir(), "eunomia-data")

archiveFile <- downloadEunomiaData(
  datasetName = "GiBleed",
  cdmVersion = "5.5",
  pathToData = dataFolder,
  overwrite = FALSE
)
archiveFile
```

`getDatabaseFile()` returns a query-ready SQLite or DuckDB file. If the archive is not already available, the function downloads it before extracting and loading the data:

```r
dataFolder <- file.path(tempdir(), "eunomia-data")

databaseFile <- getDatabaseFile(
  datasetName = "GiBleed",
  cdmVersion = "5.5",
  pathToData = dataFolder,
  dbms = "sqlite",
  overwrite = FALSE
)
databaseFile
```

The examples use a temporary folder. For a persistent cache, set the `EUNOMIA_DATA_FOLDER` environment variable or provide a persistent directory through `pathToData`.

## User documentation

- Browse the searchable [package reference](https://ohdsi.github.io/Eunomia/reference/index.html).
- Download the PDF manual from the [CRAN package page](https://CRAN.R-project.org/package=Eunomia).

## Support

- Developer questions, comments, and feedback: [OHDSI Forum](http://forums.ohdsi.org/c/developers)
- Bugs and feature requests: [GitHub issue tracker](https://github.com/OHDSI/Eunomia/issues)

## License

Eunomia is licensed under the Apache License 2.0.

## Development

Eunomia is being developed in RStudio. Its development status is ready for use.
