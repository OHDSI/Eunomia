# Create a copy of a Eunomia dataset

Creates a copy of a Eunomia database, and returns the path to the new
database file. If the dataset does not yet exist on the user's computer
it will attempt to download the source data to the the path defined by
the EUNOMIA_DATA_FOLDER environment variable.

## Usage

``` r
getDatabaseFile(
  datasetName,
  cdmVersion = "5.5",
  pathToData = Sys.getenv("EUNOMIA_DATA_FOLDER"),
  dbms = "sqlite",
  databaseFile = tempfile(fileext = paste0(".", dbms)),
  inputFormat = "csv",
  verbose = FALSE,
  overwrite = TRUE
)
```

## Arguments

- datasetName:

  The data set name as found on
  https://github.com/OHDSI/EunomiaDatasets. The data set name
  corresponds to the folder with the data set ZIP files

- cdmVersion:

  The OMOP CDM version. This version will appear in the suffix of the
  data file, for example: \<datasetName\>\_\<cdmVersion\>.zip. Default:
  '5.5'

- pathToData:

  The path where the Eunomia data is stored on the file system., By
  default the value of the environment variable "EUNOMIA_DATA_FOLDER" is
  used.

- dbms:

  The database system to use. "sqlite" (default) or "duckdb"

- databaseFile:

  The path where the database file will be copied to. By default, the
  database will be copied to a temporary folder, and will be deleted at
  the end of the R session.

- inputFormat:

  The format of the files expected in the archive. (csv or parquet)

- verbose:

  Provide additional logging details during execution

- overwrite:

  Remove and replace an existing data set.

## Value

The file path to the new Eunomia dataset copy

## Examples

``` r
if (FALSE) { # \dontrun{
conn <- DBI::dbConnect(RSQLite::SQLite(), getDatabaseFile("GiBleed"))
DBI::dbDisconnect(conn)

conn <- DBI::dbConnect(duckdb::duckdb(), getDatabaseFile("GiBleed", dbms = "duckdb"))
DBI::dbDisconnect(conn, shutdown = TRUE)

conn <- DatabaseConnector::connect(dbms = "sqlite", server = getDatabaseFile("GiBleed"))
DatabaseConnector::disconnect(conn)
} # }
```
